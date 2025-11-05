   
import ky from 'ky'

const payload = {
  event: 'test_event',
  properties: {
    key1: 'value1',
    key2: 'value2',
  },
}

const response = await ky.post(`https://api.capgo.app/private/events`, {
  json: payload,
  headers: {
    capgkey: 'your-capgkey-here',
  },
  timeout: 10000, // 10 seconds timeout
  retry: 3,
}).json()

console.log('Response:', response)
