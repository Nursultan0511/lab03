import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = { vus: 20, duration: '1m' };

export default function () {
  const res = http.post('http://localhost:3000/cart/add', null, { tags: { name: 'cart' } });
  check(res, { 'cart 200': (x) => x.status === 200 });
  sleep(1);
}
