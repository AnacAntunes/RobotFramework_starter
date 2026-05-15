import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 2,
  duration: '5s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const res = http.get('https://test.k6.io/');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'page contains welcome text': (r) => r.body.includes('Welcome to the k6.io demo site!'),
  });

  sleep(0.5);
}
