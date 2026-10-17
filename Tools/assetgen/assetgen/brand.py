"""The shop's name and tagline, read from the one brand file."""

from __future__ import annotations

import re
from dataclasses import dataclass


_NAME = re.compile(r"^\s*(?:public\s+)?static\s+let\s+name\s*=\s*\"([^\"]+)\"", re.MULTILINE)
_TAGLINE = re.compile(r"^\s*(?:public\s+)?static\s+let\s+tagline\s*=\s*\"([^\"]+)\"", re.MULTILINE)


@dataclass(frozen=True)
class BrandText:
    name: str
    tagline: str


def load_brand(path: str) -> BrandText:
    text = open(path, encoding="utf-8").read()
    name = _NAME.search(text)
    tagline = _TAGLINE.search(text)
    if name is None:
        raise ValueError(f"{path}: static let name is missing")
    if tagline is None:
        raise ValueError(f"{path}: static let tagline is missing")
    return BrandText(name=name.group(1), tagline=tagline.group(1))
