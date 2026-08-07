#!/usr/bin/env python3
"""Minimal pulsemixer-style TUI for Snapcast client volume control."""

from __future__ import annotations

import argparse
import curses
import json
import socket
import textwrap
from dataclasses import dataclass
from itertools import count
from typing import Any


@dataclass
class SnapClient:
    client_id: str
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

    def get_clients(self) -> list[SnapClient]:
        result = self.request("Server.GetStatus")
        server = result.get("server", {})
        groups = server.get("groups", [])
        clients: list[SnapClient] = []
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
                    SnapClient(
                        client_id=client.get("id", ""),
                        name=name,
                        group=group_name,
                        volume=int(volume.get("percent", 0)),
                        muted=bool(volume.get("muted", False)),
                        connected=bool(client.get("connected", False)),
                        host=host.get("name") or host.get("host") or "",
                    )
                )
        clients.sort(key=lambda item: (item.group.lower(), item.name.lower(), item.client_id.lower()))
        return clients

    def set_volume(self, client_id: str, volume: int) -> None:
        self.request(
            "Client.SetVolume",
            {"id": client_id, "volume": {"percent": max(0, min(100, int(volume)))},},
        )

    def set_mute(self, client_id: str, muted: bool) -> None:
        self.request("Client.SetMute", {"id": client_id, "mute": muted})


class SnapMixerApp:
    def __init__(self, rpc: SnapcastRPC) -> None:
        self.rpc = rpc
        self.clients: list[SnapClient] = []
        self.selected = 0
        self.status = "Connecting..."
        self.quit_requested = False

    def refresh_clients(self) -> None:
        try:
            self.clients = self.rpc.get_clients()
        except Exception as exc:
            self.clients = []
            self.selected = 0
            self.status = f"Refresh failed: {exc}"
            self.rpc.close()
            return

        if self.selected >= len(self.clients):
            self.selected = max(0, len(self.clients) - 1)
        if self.clients:
            self.status = f"Loaded {len(self.clients)} connected client(s)"
        else:
            self.status = "No connected Snapcast clients found"

    def adjust_volume(self, delta: int) -> None:
        client = self.current_client
        if client is None:
            return
        new_volume = max(0, min(100, client.volume + delta))
        self.rpc.set_volume(client.client_id, new_volume)
        self.refresh_clients()
        self.status = f"{client.name}: volume {new_volume}%"

    def set_absolute_volume(self, volume: int) -> None:
        client = self.current_client
        if client is None:
            return
        self.rpc.set_volume(client.client_id, volume)
        self.refresh_clients()
        self.status = f"{client.name}: volume {volume}%"

    def toggle_mute(self) -> None:
        client = self.current_client
        if client is None:
            return
        new_state = not client.muted
        self.rpc.set_mute(client.client_id, new_state)
        self.refresh_clients()
        self.status = f"{client.name}: {'muted' if new_state else 'unmuted'}"

    @property
    def current_client(self) -> SnapClient | None:
        if not self.clients:
            return None
        return self.clients[self.selected]

    def run(self) -> None:
        curses.wrapper(self._curses_main)

    def _curses_main(self, stdscr: Any) -> None:
        curses.curs_set(0)
        stdscr.keypad(True)
        curses.use_default_colors()
        try:
            curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_CYAN)
            curses.init_pair(2, curses.COLOR_YELLOW, -1)
            curses.init_pair(3, curses.COLOR_RED, -1)
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
        visible_rows = max(1, list_bottom - list_top)
        scroll_top = 0
        if self.selected >= visible_rows:
            scroll_top = self.selected - visible_rows + 1

        if not self.clients:
            stdscr.addnstr(list_top, 0, "No connected clients", width - 1, curses.A_DIM)
        else:
            for row, client in enumerate(self.clients[scroll_top : scroll_top + visible_rows], start=list_top):
                index = scroll_top + (row - list_top)
                attrs = curses.A_REVERSE if index == self.selected else curses.A_NORMAL
                if index == self.selected:
                    attrs |= curses.color_pair(1)
                if client.muted:
                    attrs |= curses.color_pair(3)
                line = self.format_client_line(client, width)
                stdscr.addnstr(row, 0, line, width - 1, attrs)

        stdscr.hline(height - 2, 0, ord("-"), max(1, width - 1))
        stdscr.addnstr(height - 1, 0, self.status, width - 1, curses.color_pair(2))
        stdscr.refresh()

    @staticmethod
    def format_client_line(client: SnapClient, width: int) -> str:
        meter_width = max(10, min(24, width // 4))
        filled = round(client.volume / 100 * meter_width)
        bar = "[" + ("#" * filled).ljust(meter_width, "-") + "]"
        mute = "M" if client.muted else " "
        base = f"{mute} {client.volume:>3}% {bar} {client.name}"
        suffix_parts = [part for part in (client.group, client.host, client.client_id) if part]
        suffix = " | ".join(suffix_parts)
        if suffix:
            base = f"{base}  ({suffix})"
        return textwrap.shorten(base, width=max(20, width - 1), placeholder="...")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Minimal pulsemixer-style TUI for Snapcast")
    parser.add_argument("--host", default="127.0.0.1", help="Snapcast server host")
    parser.add_argument("--port", type=int, default=1705, help="Snapcast JSON-RPC TCP port")
    parser.add_argument("--timeout", type=float, default=2.0, help="Socket timeout in seconds")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    rpc = SnapcastRPC(args.host, args.port, args.timeout)
    app = SnapMixerApp(rpc)
    try:
        app.run()
    finally:
        rpc.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
