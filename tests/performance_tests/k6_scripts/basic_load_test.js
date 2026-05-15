import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const errors = new Counter('errors');
const successRate = new Rate('successful_requests');

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    'http_req_failed': ['rate<0.01'],
    'successful_requests': ['rate>0.95'],
  },
};

export default function () {
  const getResponse = http.get('https://jsonplaceholder.typicode.com/posts');

  const getChecks = check(getResponse, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'response body not empty': (r) => r.body.length > 0,
  });

  successRate.add(getChecks);
  if (!getChecks) {
    errors.add(1);
    console.log(`GET failed: status=${getResponse.status}, duration=${getResponse.timings.duration}ms`);
  }

  const payload = JSON.stringify({ title: 'foo', body: 'bar', userId: 1 });
  const params = { headers: { 'Content-Type': 'application/json' } };
  const postResponse = http.post('https://jsonplaceholder.typicode.com/posts', payload, params);

  const postChecks = check(postResponse, {
    'status is 201': (r) => r.status === 201,
    'has id': (r) => r.json().id !== undefined,
  });

  successRate.add(postChecks);
  if (!postChecks) {
    errors.add(1);
    console.log(`POST failed: status=${postResponse.status}, duration=${postResponse.timings.duration}ms`);
  }

  sleep(Math.random() * 2 + 1);
}
