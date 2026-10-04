from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PagesPublisherTests(unittest.TestCase):
    def test_one_scheduled_publisher_owns_pages(self):
        publishers = []
        for workflow in (ROOT / '.github/workflows').glob('*.yml'):
            source = workflow.read_text()
            if 'actions/deploy-pages@' in source and re.search(r'^  schedule:', source, re.M):
                publishers.append(workflow.name)
        self.assertEqual(publishers, ['pages.yml'])

    def test_refreshes_do_not_cancel_an_active_publication(self):
        source = (ROOT / '.github/workflows/pages.yml').read_text()
        concurrency = source.split('concurrency:', 1)[1].split('\njobs:', 1)[0]
        self.assertIn('cancel-in-progress: false', concurrency)


if __name__ == '__main__':
    unittest.main()
