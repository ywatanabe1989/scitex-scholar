"""Enforces SciTeX skills quality checklist §1–§4.

Canonical: ~/.claude/skills/scitex/general/03_interface_04_skills/12_quality-checklist.md.

The helper that drives this test (``make_skill_quality_tests``) lives in
``scitex_dev``. Its module path moved between v0.11.1 (top-level
``scitex_dev._skills_quality_pytest``) and the post-0.11.1 refactor
(``scitex_dev._ecosystem._skills.skills_quality_pytest``). Probe both so the
test works against either.

WHY THE ROOT IS COMPUTED AND THEN ASSERTED
------------------------------------------
This file used to pass ``parents[1]`` as ``package_root``. That was correct
while it sat at ``tests/test_skills_quality.py`` and became wrong the moment
it moved to ``tests/skills/`` (c978ba3, 2026-08-16): ``parents[1]`` then named
``tests/``, which ships no ``_skills/``. The helper answers an empty corpus
with a single function whose whole body is ``pytest.skip()``, so from that
commit until 2026-09-06 this gate REPORTED SUCCESS WITHOUT CHECKING ANYTHING
— pytest exits 0 when every test skips, and a skip is not a failure.

So the root is no longer derived by counting directories, and
``test_the_skill_corpus_is_not_empty`` below fails rather than skips when the
corpus cannot be found. A package that ships ``_skills/`` must never satisfy
this file by skipping; if the layout moves again, that test goes RED and
names the directory it looked in.
"""

from __future__ import annotations

from pathlib import Path

import pytest

try:
    from scitex_dev._skills_quality_pytest import make_skill_quality_tests
except ImportError:
    try:
        from scitex_dev._ecosystem._skills.skills_quality_pytest import (
            make_skill_quality_tests,
        )
    except ImportError:  # pragma: no cover — depends on which scitex-dev is installed
        pytest.skip(
            "scitex-dev does not expose make_skill_quality_tests at any known "
            "path; skipping (install scitex-dev>=0.11.1 to enable).",
            allow_module_level=True,
        )

# The repository root: the directory holding pyproject.toml, found by walking
# up from this file. Anchored on a file that only the root has, so moving this
# test to another depth cannot silently repoint it.
PACKAGE_ROOT = next(
    parent for parent in Path(__file__).resolve().parents if (parent / "pyproject.toml").is_file()
)

SKILLS_DIR = PACKAGE_ROOT / "src" / "scitex_scholar" / "_skills"


def test_the_skill_corpus_is_not_empty():
    """The gate must fail, not skip, when it cannot find what it grades."""
    # Arrange
    expected = True
    # Act
    found = SKILLS_DIR.is_dir() and any(SKILLS_DIR.iterdir())
    # Assert
    assert found is expected, (
        f"no skills found under {SKILLS_DIR} — scitex-scholar ships a skill "
        "corpus, so an empty result means this test is looking in the wrong "
        "place, not that the package has no skills. Fix PACKAGE_ROOT rather "
        "than letting the quality checks skip."
    )


test_skills_quality = make_skill_quality_tests(package_root=PACKAGE_ROOT)

# EOF
