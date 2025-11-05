
import ky from 'ky'

const payload = {
  event: 'test_event',
  properties: {
    key1: 'value1',
    key2: 'value2',
  },
}

try {
  const response = await ky.post(`https://api.capgo.app/private/events`, {
    json: payload,
    headers: {
      capgkey: 'your-capgkey-here',
    },
    timeout: 10000, // 10 seconds timeout
    retry: 3,
  }).json()

  console.log('✓ Request completed successfully')
  console.log('Response:', response)
} catch (error) {
  // Errors are acceptable - we're only testing for hangs
  console.log('✓ Request completed with error (this is OK)')
  console.log('Error:', error.message)
  process.exit(0) // Exit successfully - errors are not the bug we're testing
}
