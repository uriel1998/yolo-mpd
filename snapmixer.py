#!/usr/bin/env python3
"""Minimal pulsemixer-style TUI for Snapcast client volume control."""

from __future__ import annotations

import argparse
import curses
import json
import os
import pathlib
import socket
import subprocess
import textwrap
from dataclasses import dataclass
from itertools import count
from typing import Any


@dataclass
class MixerRow:
    backend: str
    row_id: str
    name: str
    group: str
    volume: int
    muted: bool
    connected: bool
    host: str


class SnapcastRPC:
    def __init__(self, host: str, port: int, timeout: float) -> None:
        self.host = host
        self.port = port
        self.timeout = timeout
        self._sock: socket.socket | None = None
        self._reader: Any = None
        self._ids = count(1)

    def connect(self) -> None:
        self.close()
        self._sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self._sock.settimeout(self.timeout)
        self._reader = self._sock.makefile("r", encoding="utf-8", newline="\n")

    def close(self) -> None:
        if self._reader is not None:
            self._reader.close()
            self._reader = None
        if self._sock is not None:
            self._sock.close()
            self._sock = None

    def request(self, method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
        if self._sock is None or self._reader is None:
            self.connect()

        request_id = next(self._ids)
        payload: dict[str, Any] = {"jsonrpc": "2.0", "id": request_id, "method": method}
        if params is not None:
            payload["params"] = params

        message = json.dumps(payload) + "\r\n"
        assert self._sock is not None
        assert self._reader is not None
        self._sock.sendall(message.encode("utf-8"))

        while True:
            line = self._reader.readline()
            if not line:
                raise ConnectionError("Snapcast server closed the connection")
            response = json.loads(line)
            if response.get("id") != request_id:
                continue
            if "error" in response:
                raise RuntimeError(response["error"])
            return response.get("result", {})

    def get_clients(self) -> list[MixerRow]:
        result = self.request("Server.GetStatus")
        server = result.get("server", {})
        groups = server.get("groups", [])
        clients: list[MixerRow] = []
        for group in groups:
            group_name = group.get("name") or group.get("id") or "group"
            for client in group.get("clients", []):
                if not client.get("connected", False):
                    continue
                config = client.get("config", {})
                host = client.get("host", {}) or {}
                volume = config.get("volume", {}) or {}
                name = (
                    config.get("name")
                    or host.get("name")
                    or host.get("host")
                    or client.get("id")
                    or "unknown"
                )
                clients.append(
                    MixerRow(
                        backend="snapcast",
                        row_id=client.get("id", ""),
                        name=name,
                        group=group_name,
                        volume=int(volume.get("percent", 0)),
                        muted=bool(volume.get("muted", False)),
                        connected=bool(client.get("connected", False)),
                        host=host.get("name") or host.get("host") or "",
                    )
                )
        clients.sort(key=lambda item: (item.group.lower(), item.name.lower(), item.row_id.lower()))
        return clients

    def set_volume(self, client_id: str, volume: int) -> None:
        self.request(
            "Client.SetVolume",
            {"id": client_id, "volume": {"percent": max(0, min(100, int(volume)))},},
        )

    def set_mute(self, client_id: str, muted: bool) -> None:
        self.request("Client.SetMute", {"id": client_id, "mute": muted})


class MPDController:
    def __init__(self, repo_root: pathlib.Path) -> None:
        self.repo_root = repo_root
        self.host = ""
        self.port = ""
        self.password = ""
        self.available = False
        self._last_nonzero_volume = 50
        self._load_config()

    def _load_config(self) -> None:
        env_host = os.environ.get("MPD_HOST", "").strip()
        env_port = os.environ.get("MPD_PORT", "").strip()
        env_password = os.environ.get("MPD_PASSWORD", "").strip()

        file_values = self._read_env_file(self.repo_root / "maubot_vars.env")

        self.host = env_host or file_values.get("MPD_HOST", "")
        self.port = env_port or file_values.get("MPD_PORT", "")
        self.password = env_password or file_values.get("MPD_PASSWORD", "")
        self.available = bool(self.host) and self._has_mpc()

    @staticmethod
    def _read_env_file(path: pathlib.Path) -> dict[str, str]:
        values: dict[str, str] = {}
        if not path.is_file():
            return values
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[7:].strip()
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip("\"'")
            if key:
                values[key] = value
        return values

    @staticmethod
    def _has_mpc() -> bool:
        return any(
            os.access(os.path.join(directory, "mpc"), os.X_OK)
            for directory in os.environ.get("PATH", "").split(os.pathsep)
            if directory
        )

    def _base_command(self) -> list[str]:
        if not self.available:
            raise RuntimeError("MPD control unavailable: missing mpc or MPD_HOST")
        command = ["mpc", "--host", self.host]
        if self.port:
            command.extend(["--port", self.port])
        if self.password and "@" not in self.host:
            command.extend(["--password", self.password])
        return command

    def _run(self, *args: str) -> str:
        command = [*self._base_command(), *args]
        completed = subprocess.run(
            command,
            check=True,
            text=True,
            capture_output=True,
        )
        return completed.stdout

    def get_row(self) -> MixerRow | None:
        if not self.available:
            return None
        try:
            output = self._run("volume")
        except Exception:
            return None

        volume = self._parse_volume(output)
        muted = volume == 0
        if volume > 0:
            self._last_nonzero_volume = volume
        host_label = self.host
        if "@" in host_label:
            host_label = host_label.split("@", 1)[1]
        return MixerRow(
            backend="mpd",
            row_id="mpd-master",
            name="MPD master",
            group="MPD",
            volume=volume,
            muted=muted,
            connected=True,
            host=host_label,
        )

    @staticmethod
    def _parse_volume(output: str) -> int:
        for line in output.splitlines():
            if "volume:" not in line:
                continue
            try:
                value = line.split("volume:", 1)[1].strip().rstrip("%")
                return max(0, min(100, int(value)))
            except ValueError:
                continue
        raise RuntimeError("Could not determine MPD volume")

    def set_volume(self, volume: int) -> None:
        volume = max(0, min(100, int(volume)))
        self._run("volume", str(volume))
        if volume > 0:
            self._last_nonzero_volume = volume

    def toggle_mute(self) -> bool:
        row = self.get_row()
        if row is None:
            raise RuntimeError("MPD control unavailable")
        if row.volume == 0:
            restore = max(1, self._last_nonzero_volume)
            self.set_volume(restore)
            return False
        self._last_nonzero_volume = row.volume
        self.set_volume(0)
        return True


class SnapMixerApp:
    def __init__(self, rpc: SnapcastRPC, mpd: MPDController) -> None:
        self.rpc = rpc
        self.mpd = mpd
        self.clients: list[MixerRow] = []
        self.selected = 0
        self.status = "Connecting..."
        self.quit_requested = False

    def refresh_clients(self) -> None:
        rows: list[MixerRow] = []
        mpd_row = self.mpd.get_row()
        if mpd_row is not None:
            rows.append(mpd_row)
        try:
            rows.extend(self.rpc.get_clients())
        except Exception as exc:
            self.clients = rows
            if not self.clients:
                self.selected = 0
            elif self.selected >= len(self.clients):
                self.selected = len(self.clients) - 1
            self.status = f"Snapcast refresh failed: {exc}"
            self.rpc.close()
        else:
            self.clients = rows

        if self.selected >= len(self.clients):
            self.selected = max(0, len(self.clients) - 1)
        if self.clients:
            snapcast_count = sum(1 for client in self.clients if client.backend == "snapcast")
            if mpd_row is not None:
                self.status = f"Loaded MPD master plus {snapcast_count} connected Snapcast client(s)"
            else:
                self.status = f"Loaded {snapcast_count} connected Snapcast client(s)"
        else:
            self.status = "No connected Snapcast clients found, and MPD control is unavailable"

    def adjust_volume(self, delta: int) -> None:
        client = self.current_client
        if client is None:
            return
        new_volume = max(0, min(100, client.volume + delta))
        if client.backend == "mpd":
            self.mpd.set_volume(new_volume)
        else:
            self.rpc.set_volume(client.row_id, new_volume)
        self.refresh_clients()
        self.status = f"{client.name}: volume {new_volume}%"

    def set_absolute_volume(self, volume: int) -> None:
        client = self.current_client
        if client is None:
            return
        if client.backend == "mpd":
            self.mpd.set_volume(volume)
        else:
            self.rpc.set_volume(client.row_id, volume)
        self.refresh_clients()
        self.status = f"{client.name}: volume {volume}%"

    def toggle_mute(self) -> None:
        client = self.current_client
        if client is None:
            return
        if client.backend == "mpd":
            new_state = self.mpd.toggle_mute()
        else:
            new_state = not client.muted
            self.rpc.set_mute(client.row_id, new_state)
        self.refresh_clients()
        self.status = f"{client.name}: {'muted' if new_state else 'unmuted'}"

    @property
    def current_client(self) -> MixerRow | None:
        if not self.clients:
            return None
        return self.clients[self.selected]

    def run(self) -> None:
        curses.wrapper(self._curses_main)

    def build_display_rows(self) -> list[tuple[str, MixerRow | str]]:
        display_rows: list[tuple[str, MixerRow | str]] = []
        mpd_rows = [client for client in self.clients if client.backend == "mpd"]
        snapcast_rows = [client for client in self.clients if client.backend == "snapcast"]

        if mpd_rows:
            display_rows.append(("header", "MPD master"))
            display_rows.extend(("client", client) for client in mpd_rows)
        if snapcast_rows:
            display_rows.append(("header", "Snapcast clients"))
            display_rows.extend(("client", client) for client in snapcast_rows)
        return display_rows

    def selected_display_index(self, display_rows: list[tuple[str, MixerRow | str]]) -> int:
        client_index = -1
        for display_index, (row_type, payload) in enumerate(display_rows):
            if row_type != "client":
                continue
            client_index += 1
            if client_index == self.selected:
                return display_index
        return 0

    def _curses_main(self, stdscr: Any) -> None:
        curses.curs_set(0)
        stdscr.keypad(True)
        curses.use_default_colors()
        try:
            curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_CYAN)
            curses.init_pair(2, curses.COLOR_YELLOW, -1)
            curses.init_pair(3, curses.COLOR_RED, -1)
            curses.init_pair(4, curses.COLOR_GREEN, -1)
        except curses.error:
            pass

        self.refresh_clients()

        while not self.quit_requested:
            self.draw(stdscr)
            key = stdscr.getch()
            try:
                self.handle_key(key)
            except Exception as exc:
                self.status = str(exc)
                self.rpc.close()

    def handle_key(self, key: int) -> None:
        if key in (ord("q"), 27):
            self.quit_requested = True
        elif key in (ord("j"), curses.KEY_DOWN):
            if self.clients:
                self.selected = min(len(self.clients) - 1, self.selected + 1)
        elif key in (ord("k"), curses.KEY_UP):
            if self.clients:
                self.selected = max(0, self.selected - 1)
        elif key in (ord("h"), curses.KEY_LEFT):
            self.adjust_volume(-1)
        elif key in (ord("l"), curses.KEY_RIGHT):
            self.adjust_volume(1)
        elif key == ord("H"):
            self.adjust_volume(-5)
        elif key == ord("L"):
            self.adjust_volume(5)
        elif key == ord("m"):
            self.toggle_mute()
        elif key == ord("r"):
            self.refresh_clients()
        elif key in map(ord, "`1234567890"):
            absolute = 100 if key == ord("0") else 0 if key == ord("`") else (key - ord("0")) * 10
            self.set_absolute_volume(absolute)

    def draw(self, stdscr: Any) -> None:
        stdscr.erase()
        height, width = stdscr.getmaxyx()

        title = "snapmixer"
        controls = "j/k move  h/l +/-1  H/L +/-5  0-9 set  m mute  r refresh  q quit"
        stdscr.addnstr(0, 0, title, width - 1, curses.A_BOLD)
        stdscr.addnstr(1, 0, controls, width - 1)
        stdscr.hline(2, 0, ord("-"), max(1, width - 1))

        list_top = 3
        list_bottom = max(list_top, height - 3)
        visible_rows = max(1, list_bottom - list_top + 1)
        display_rows = self.build_display_rows()
        scroll_top = 0
        selected_display_index = self.selected_display_index(display_rows)
        if selected_display_index >= visible_rows:
            scroll_top = selected_display_index - visible_rows + 1

        if not self.clients:
            stdscr.addnstr(list_top, 0, "No connected clients", width - 1, curses.A_DIM)
        else:
            visible_display_rows = display_rows[scroll_top : scroll_top + visible_rows]
            client_index = scroll_top and sum(1 for row_type, _ in display_rows[:scroll_top] if row_type == "client") or 0
            for row, (row_type, payload) in enumerate(visible_display_rows, start=list_top):
                if row_type == "header":
                    stdscr.addnstr(row, 0, str(payload), width - 1, curses.A_BOLD | curses.color_pair(4))
                    continue

                client = payload
                assert isinstance(client, MixerRow)
                attrs = curses.A_NORMAL
                if client_index == self.selected:
                    attrs |= curses.A_REVERSE | curses.color_pair(1)
                elif client.muted:
                    attrs |= curses.color_pair(3)
                elif client.backend == "mpd":
                    attrs |= curses.color_pair(4)
                line = self.format_client_line(client, width)
                stdscr.addnstr(row, 0, line, width - 1, attrs)
                client_index += 1

        stdscr.hline(height - 2, 0, ord("-"), max(1, width - 1))
        stdscr.addnstr(height - 1, 0, self.status, width - 1, curses.color_pair(2))
        stdscr.refresh()

    @staticmethod
    def format_client_line(client: MixerRow, width: int) -> str:
        meter_width = max(10, min(24, width // 4))
        filled = round(client.volume / 100 * meter_width)
        bar = "[" + ("#" * filled).ljust(meter_width, "-") + "]"
        mute = "M" if client.muted else " "
        base = f"{mute} {client.volume:>3}% {bar} {client.name}"
        suffix_parts = [part for part in (client.group, client.host, client.row_id if client.backend != "mpd" else "") if part]
        suffix = " | ".join(suffix_parts)
        if suffix:
            base = f"{base}  ({suffix})"
        return textwrap.shorten(base, width=max(20, width - 1), placeholder="...")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Minimal pulsemixer-style TUI for Snapcast plus optional MPD master volume",
        epilog=(
            "MPD master control uses MPD_HOST/MPD_PORT/MPD_PASSWORD from the environment "
            "first, then falls back to maubot_vars.env in the repository root."
        ),
    )
    parser.add_argument("--host", default="127.0.0.1", help="Snapcast server host")
    parser.add_argument("--port", type=int, default=1705, help="Snapcast JSON-RPC TCP port")
    parser.add_argument("--timeout", type=float, default=2.0, help="Socket timeout in seconds")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    rpc = SnapcastRPC(args.host, args.port, args.timeout)
    app = SnapMixerApp(rpc, MPDController(pathlib.Path(__file__).resolve().parent))
    try:
        app.run()
    finally:
        rpc.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
