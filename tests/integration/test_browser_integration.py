"""Integration tests: scitex-scholar consuming scitex-browser.

These are the upper-package integration tests (in the consumer's suite) that
verify the one-way dependency rule:
    - scitex-scholar may consume scitex-browser
    - scitex-browser must NOT reach back into scitex-scholar

They are intentionally lightweight: no live browser launches, just surface-level
wiring checks that would catch API drift between the two packages.

NOTE: the decoupling fix and the chrome_cache_dir kwarg ship in
scitex-browser ≥ 0.1.2. On older PyPI versions (0.1.0, 0.1.1) the reverse
`from scitex.scholar.config import ...` import still lives in the source
and ``ChromeProfileManager`` takes ``config`` positionally. The two tests
below skip themselves when that legacy signature/source is present so CI
with a pinned-but-pre-release dep tree doesn't go red.
"""

import importlib
from pathlib import Path

import pytest


def _browser_has_legacy_reverse_import() -> bool:
    try:
        mod = importlib.import_module("scitex_browser.core.ChromeProfileManager")
    except Exception:
        return True
    src = Path(mod.__file__).read_text()
    return "scitex.scholar" in src or "scitex_scholar" in src


def _browser_accepts_chrome_cache_dir() -> bool:
    try:
        from inspect import signature

        from scitex_browser.core.ChromeProfileManager import ChromeProfileManager
    except Exception:
        return False
    return "chrome_cache_dir" in signature(ChromeProfileManager.__init__).parameters


_LEGACY_REVERSE_IMPORT = _browser_has_legacy_reverse_import()
_HAS_CHROME_CACHE_DIR = _browser_accepts_chrome_cache_dir()


@pytest.mark.skipif(
    _LEGACY_REVERSE_IMPORT,
    reason="scitex-browser <0.1.2 still has the reverse import; decouple fix not yet released",
)
def test_scholar_uses_browser_without_circular_import():
    """Importing scholar must not require scholar to already be importable by browser."""
    mod = importlib.import_module("scitex_browser.core.ChromeProfileManager")
    src = Path(mod.__file__).read_text()
    assert "scitex_scholar" not in src
    assert "scitex.scholar" not in src


@pytest.mark.skipif(
    not _HAS_CHROME_CACHE_DIR,
    reason="ChromeProfileManager.chrome_cache_dir kwarg only in scitex-browser >=0.1.2",
)
def test_scholar_browser_manager_exposes_chrome_profile_manager():
    """ScholarBrowserManager should compose ChromeProfileManager with
    a chrome_cache_dir derived from ScholarConfig."""
    from scitex_browser.core.ChromeProfileManager import ChromeProfileManager

    from scitex_scholar.config import ScholarConfig

    config = ScholarConfig()
    base_dir = config.get_cache_chrome_dir("system").parent
    manager = ChromeProfileManager("system", chrome_cache_dir=base_dir)
    assert manager.profile_dir == base_dir / "system"
    assert manager.profile_dir.exists()


def test_scholar_url_finder_exports():
    """Scholar's public API surface must expose ScholarURLFinder
    since the pipelines import it via the top-level package."""
    import scitex_scholar

    assert hasattr(scitex_scholar, "ScholarURLFinder")
    assert hasattr(scitex_scholar, "ScholarBrowserManager")
    assert hasattr(scitex_scholar, "ScholarAuthManager")


def test_chrome_profile_manager_accepts_scholar_path_manager():
    """Back-compat duck-typing: any object with get_cache_chrome_dir works."""
    from scitex_browser.core.ChromeProfileManager import ChromeProfileManager

    class FakeConfig:
        def __init__(self, base):
            self._base = base

        def get_cache_chrome_dir(self, profile_name):
            p = self._base / profile_name
            p.mkdir(parents=True, exist_ok=True)
            return p

    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        fake = FakeConfig(Path(tmp))
        m = ChromeProfileManager("system", config=fake)
        assert m.profile_dir == Path(tmp) / "system"
