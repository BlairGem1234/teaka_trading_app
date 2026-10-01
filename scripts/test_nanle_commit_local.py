#!/usr/bin/env python3
"""Exercise both retained paste helpers only in isolated temporary repositories."""
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent
FILES = ['Cargo.toml', 'Cargo.lock', 'src/commands/mod.rs', 'src/utils/database.rs', 'src/utils/mod.rs']

class LocalCommitTests(unittest.TestCase):
    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.repo, env=self.env, stderr=subprocess.STDOUT).decode().strip()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = Path(self.tmp.name) / 'StarForge'
        self.repo.mkdir()
        self.env = {**os.environ, 'HOME': self.tmp.name, 'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull, 'GIT_OPTIONAL_LOCKS': '0'}
        for key in list(self.env):
            if key.startswith('GIT_') and key not in ('GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_GLOBAL', 'GIT_OPTIONAL_LOCKS'):
                del self.env[key]
        self.git('init', '-b', 'master')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.git('remote', 'add', 'origin', 'https://github.com/Nanle-code/StarForge.git')
        for name in FILES + ['other.txt']:
            p = self.repo / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('base\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')
        (self.repo / FILES[0]).write_text('compile fix\n')

    def snapshot(self):
        return {str(p.relative_to(self.repo)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.repo.rglob('*') if p.is_file()}

    def run_helper(self, platform, confirmation='', missing=False):
        text = (SCRIPTS / f'PASTE_{platform}_NANLE_GIT_COMMIT_LOCAL.txt').read_text()
        original = ('/c' if platform == 'GITBASH' else '/mnt/c') + '/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge'
        target = self.repo / 'missing' if missing else self.repo
        self.assertIn(original, text)
        text = text.replace(original, str(target))
        script = Path(self.tmp.name) / 'helper.sh'
        script.write_text(text)
        return subprocess.run(['bash', str(script)], cwd=self.repo, env=self.env, input=confirmation, text=True, capture_output=True)

    def test_preview_preserves_every_file(self):
        for platform in ('GITBASH', 'WSL'):
            before = self.snapshot()
            result = self.run_helper(platform)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('PREVIEW', result.stdout)
            self.assertEqual(before, self.snapshot())

    def test_wrong_confirmation_preserves_every_file(self):
        for platform in ('GITBASH', 'WSL'):
            before = self.snapshot()
            result = self.run_helper(platform, 'COMMIT stale-head\n')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(before, self.snapshot())

    def test_opt_in_and_rerun(self):
        platform = os.environ.get('NANLE_TEST_PLATFORM', 'WSL')
        head = self.git('rev-parse', 'HEAD')
        (self.repo / 'harmless-untracked.txt').write_text('leave alone\n')
        result = self.run_helper(platform, f'COMMIT {head}\n')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git('branch', '--show-current'), 'local/cargo-check-fixes')
        self.assertNotEqual(head, self.git('rev-parse', 'HEAD'))
        self.assertEqual(self.git('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD'), FILES[0])
        self.assertEqual(self.git('status', '--porcelain'), '?? harmless-untracked.txt')
        before = self.snapshot()
        self.run_helper(platform, f'COMMIT {head}\n')
        self.assertEqual(before, self.snapshot())

    def test_guards_preserve_every_file(self):
        platform = os.environ.get('NANLE_TEST_PLATFORM', 'WSL')
        cases = ['missing_directory', 'wrong_origin', 'staged', 'outside', 'branch_exists', 'no_change', 'merge', 'detached', 'missing_file', 'staged_other', 'symlink', 'git_override']
        for case in cases:
            with self.subTest(case=case):
                # Each guard starts from a fresh independent fixture.
                self.setUp()
                head = self.git('rev-parse', 'HEAD')
                if case == 'wrong_origin': self.git('remote', 'set-url', 'origin', 'https://example.invalid/wrong.git')
                if case == 'staged': self.git('add', FILES[0])
                if case == 'staged_other':
                    (self.repo / 'other.txt').write_text('unrelated\n')
                    self.git('add', 'other.txt')
                if case == 'symlink':
                    (self.repo / FILES[1]).unlink()
                    (self.repo / FILES[1]).symlink_to('other.txt')
                if case == 'git_override': self.env['GIT_INDEX_FILE'] = str(self.repo / '.git/alternate-index')
                if case == 'outside': (self.repo / 'other.txt').write_text('unrelated\n')
                if case == 'branch_exists': self.git('branch', 'local/cargo-check-fixes')
                if case == 'no_change': (self.repo / FILES[0]).write_text('base\n')
                if case == 'merge': (self.repo / '.git/MERGE_HEAD').write_text(head + '\n')
                if case == 'detached': self.git('checkout', '--detach')
                if case == 'missing_file': (self.repo / FILES[1]).unlink()
                before = self.snapshot()
                result = self.run_helper(platform, f'COMMIT {head}\n', missing=case == 'missing_directory')
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(before, self.snapshot())

    def test_change_during_prompt_is_rejected(self):
        platform = os.environ.get('NANLE_TEST_PLATFORM', 'WSL')
        # Prepare the same translated helper used in the other fixture tests.
        self.run_helper(platform)
        head = self.git('rev-parse', 'HEAD')
        process = subprocess.Popen(['bash', str(Path(self.tmp.name) / 'helper.sh')],
                                   cwd=self.repo, env=self.env, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(lambda: process.kill() if process.poll() is None else None)
        output = ''
        while not output.endswith('otherwise press Enter: '):
            char = process.stdout.read(1)
            self.assertTrue(char, 'helper exited before confirmation prompt')
            output += char
        (self.repo / FILES[0]).write_text('changed after review\n')
        before = self.snapshot()
        stdout, stderr = process.communicate(f'COMMIT {head}\n', timeout=10)
        self.assertNotEqual(process.returncode, 0, stdout + stderr)
        self.assertIn('Files changed since preview', stderr)
        self.assertEqual(before, self.snapshot())

    def test_failed_branch_creation_stops_before_commit(self):
        platform = os.environ.get('NANLE_TEST_PLATFORM', 'WSL')
        head = self.git('rev-parse', 'HEAD')
        lock = self.repo / '.git/refs/heads/local/cargo-check-fixes.lock'
        lock.parent.mkdir(parents=True)
        lock.write_text('fixture lock\n')
        before = self.snapshot()
        result = self.run_helper(platform, f'COMMIT {head}\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(before, self.snapshot())

    def test_failed_commit_preserves_work_and_stops(self):
        platform = os.environ.get('NANLE_TEST_PLATFORM', 'WSL')
        head = self.git('rev-parse', 'HEAD')
        hook = self.repo / '.git/hooks/pre-commit'
        hook.write_text('#!/bin/sh\necho FIXTURE_COMMIT_REJECTED >&2\nexit 1\n')
        hook.chmod(0o755)
        result = self.run_helper(platform, f'COMMIT {head}\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('FIXTURE_COMMIT_REJECTED', result.stderr)
        self.assertNotIn('## local/', result.stdout)
        self.assertEqual(self.git('rev-parse', 'HEAD'), head)
        self.assertEqual(self.git('branch', '--show-current'), 'local/cargo-check-fixes')
        self.assertEqual((self.repo / FILES[0]).read_text(), 'compile fix\n')
        self.assertEqual(self.git('diff', '--cached', '--name-only'), '')

if __name__ == '__main__':
    unittest.main()
