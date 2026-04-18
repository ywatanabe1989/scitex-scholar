"""Integration tests: scitex-scholar consuming scitex-browser.

These are the upper-package integration tests (in the consumer's suite) that
verify the one-way dependency rule:
    - scitex-scholar may consume scitex-browser
    - scitex-browser must NOT reach back into scitex-scholar

They are intentionally lightweight: no live browser launches, just surface-level
wiring checks that would catch API drift between the two packages.
"""

from pathlib import Path


def test_scholar_uses_browser_without_circular_import():
    """Importing scholar must not require scholar to already be importable by browser."""
    import importlib

    browser_mod = importlib.import_module("scitex_browser.core.ChromeProfileManager")
    src = Path(browser_mod.__file__).read_text()
    assert "scitex_scholar" not in src
    assert "scitex.scholar" not in src


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
