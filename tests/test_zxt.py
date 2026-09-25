import importlib.machinery
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT=Path(__file__).resolve().parents[1]
LOADER=importlib.machinery.SourceFileLoader("zxt_module",str(ROOT/"zxt"))
SPEC=importlib.util.spec_from_loader(LOADER.name,LOADER)
zxt=importlib.util.module_from_spec(SPEC)
LOADER.exec_module(zxt)

class ZxtTests(unittest.TestCase):
    def test_actual_disabled_parses_true_and_false(self):
        with mock.patch.object(
            zxt,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'disabled services = {\n    "com.test" => true\n}\n',""),
        ):
            self.assertTrue(zxt.actual_disabled("system","com.test"))
        with mock.patch.object(
            zxt,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'disabled services = {\n    "com.test" => false\n}\n',""),
        ):
            self.assertFalse(zxt.actual_disabled("system","com.test"))

    def test_actual_disabled_handles_legacy_wording(self):
        with mock.patch.object(
            zxt,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'"com.test" => disabled\n',""),
        ):
            self.assertTrue(zxt.actual_disabled("gui/501","com.test"))

    def test_state_round_trip(self):
        entry=zxt.encode_state("system","com.example.service")
        self.assertEqual(entry,"system|com.example.service")
        self.assertEqual(zxt.decode_state(entry),("system","com.example.service"))
        self.assertEqual(zxt.decode_state("legacy.label"),(None,"legacy.label"))

    def test_invalid_config_falls_back_to_safe_defaults(self):
        with tempfile.TemporaryDirectory() as temp:
            config_path=Path(temp)/"config.json"
            config_path.write_text(json.dumps({
                "profile":"broken",
                "siri":"broken",
                "intelligence":"broken",
                "spotlight":"broken",
            }))
            with mock.patch.object(zxt,"CONFIG_FILE",config_path):
                config=zxt.load_config()
            self.assertEqual(config,zxt.DEFAULT_CONFIG)

    def test_dry_run_does_not_mutate_state(self):
        with mock.patch.object(zxt,"domains_for",return_value={"user"}), \
             mock.patch.object(zxt,"restore_entry") as restore_entry, \
             mock.patch.object(zxt,"save_state") as save_state, \
             mock.patch.object(zxt,"apply_spotlight") as apply_spotlight:
            zxt.apply(dry_run=True)
        restore_entry.assert_not_called()
        save_state.assert_not_called()
        apply_spotlight.assert_not_called()

    def test_installer_never_creates_root_daemon(self):
        text=(ROOT/"install.sh").read_text()
        self.assertNotIn('sudo tee "$SYSTEM_DAEMON"',text)
        self.assertNotIn('bootstrap system "$SYSTEM_DAEMON"',text)
        self.assertIn("launchctl disable overrides",text)

if __name__=="__main__":
    unittest.main()
