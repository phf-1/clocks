# [[id:d94384e8-a62d-4617-a366-f88f7a8887ed][Help]]
#
# This module extracts and prints a help from a script.

from __future__ import annotations
import re
from dataclasses import dataclass, field
from pathlib import Path

CMD_RE     = re.compile(r" *# (,.+)$")
SECTION_RE = re.compile(r" *# ([^ #][^#]*?) #$")
DESC_RE    = re.compile(r" *#   (.+)")

@dataclass
class Section:
    """
    Name :≡ String
    Command :≡ String
    Description :≡ String
    Content :≡ List(Command × Description)
    Section 
      mk      : Name Content → Section
      elim    : (Name Content → C) → Section → C
      name    : Section → Name
      content : Section → List(Command × Description)
      add     : Section Command Description → Section
    """
    
    _name:    str
    _content: list[tuple[str, str]] = field(default_factory=list)

    @staticmethod
    def mk(name: str, content: list[tuple[str, str]]) -> "Section":
        return Section(name, content)

    @staticmethod
    def is_a(x):
        return isinstance(x, Section)

    @staticmethod
    def check(x):
        if not Section.is_a(x):
            raise ValueError("x is not a Section")

    @staticmethod
    def elim(f):
        def use(sec: "Section"):
            Section.check(sec)
            return f(sec._name, sec._content)
        return use

    @staticmethod
    def name(sec: "Section") -> str:
        return Section.elim(lambda n, _c: n)(sec)

    @staticmethod
    def content(sec: "Section") -> list[tuple[str, str]]:
        return Section.elim(lambda _n, c: c)(sec)

    @staticmethod
    def add(sec: "Section", cmd: str, desc: str) -> "Section":
        def _add(name, content):
            return Section.mk(name, content + [(cmd, desc)])
        return Section.elim(_add)(sec)

    @staticmethod
    def command_width(sec: "Section") -> int:
        c = Section.content(sec)
        return max((len(cmd) for cmd, _ in c), default=0)

    @staticmethod
    def description_width(sec: "Section") -> int:
        c = Section.content(sec)
        return max((len(desc) for _, desc in c), default=0)

    @staticmethod
    def width(sec: "Section") -> int:
        return max(
            len(Section.name(sec)),
            Section.command_width(sec),
            Section.description_width(sec),
        )

Doc = list[Section]

class Help:
    """
    Help
      doc    : Path → Doc
      string : Path → String
    """
    
    @staticmethod
    def doc(path: Path) -> Doc:
        lines   = path.read_text(encoding="utf-8").splitlines()
        doc: Doc        = []
        cur_sec: Section | None = None
        cur_cmd: str    | None  = None

        for line in lines:
            if m := SECTION_RE.match(line):
                cur_sec = Section.mk(m.group(1).strip(), [])
                cur_cmd = None
                doc.append(cur_sec)
            elif cur_sec is not None and (m := CMD_RE.match(line)):
                cur_cmd = m.group(1).split()[0]
            elif cur_cmd is not None and (m := DESC_RE.match(line)):
                cur_sec = Section.add(cur_sec, cur_cmd, m.group(1))
                doc[-1] = cur_sec
                cur_cmd = None

        return [s for s in doc if Section.content(s)]

    @staticmethod
    def string(path: Path) -> str:
        doc  = Help.doc(path)
        if not doc:
            return ""

        cmd_w  = max(Section.command_width(s) for s in doc)
        desc_w = max(Section.description_width(s) for s in doc)
        total  = cmd_w + 3 + desc_w   # 3 = "  " separator + at least one space

        lines: list[str] = []
        for sec in doc:
            name = Section.name(sec)
            # Box-drawing header: ┌─ Name ──...─┐
            pad   = total - len(name) - 2        # 2 = "─ " prefix space
            lines.append(f"┌─ {name} {'─' * max(pad, 0)}┐")
            for cmd, desc in Section.content(sec):
                lines.append(f"│ {cmd:<{cmd_w}}  {desc:<{desc_w}} │")
            lines.append(f"└{'─' * (total + 1)}┘")
            lines.append("")

        return "\n".join(lines)
