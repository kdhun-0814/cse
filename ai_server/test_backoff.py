
import unittest
from unittest.mock import patch, MagicMock
import time
from gemini_classifier import classify_notice_with_gemini

class TestBackoff(unittest.TestCase):
    @patch('requests.post')
    @patch('time.sleep')
    def test_backoff_logic(self, mock_sleep, mock_post):
        # Setup mock to fail with 429 twice, then succeed
        response_429 = MagicMock()
        response_429.status_code = 429
        
        response_200 = MagicMock()
        response_200.status_code = 200
        response_200.json.return_value = {
            'candidates': [{'content': {'parts': [{'text': '학사'}]}}]
        }
        
        # Determine side effects: 2 failures, then 1 success
        mock_post.side_effect = [response_429, response_429, response_200]
        
        # Run
        category = classify_notice_with_gemini("테스트 제목")
        
        # Verify
        self.assertEqual(category, "학사")
        self.assertEqual(mock_post.call_count, 3)
        
        # Check sleep calls
        # Expected waits: 15, 30
        calls = mock_sleep.call_args_list
        # We might have other sleeps (like 1 sec for other errors), but here we expect backoff
        # Filter for our backoff values
        backoff_waits = [args[0] for args, _ in calls if args[0] >= 15]
        print(f"Sleep calls: {backoff_waits}")
        self.assertIn(15, backoff_waits)
        self.assertIn(30, backoff_waits)

if __name__ == '__main__':
    unittest.main()
