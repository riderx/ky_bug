
import ky from 'ky'

console.log('=== SCRIPT START - Node:', process.version, '===')

const payload = {
  event: 'test_event',
  properties: {
    key1: 'value1',
    key2: 'value2',
  },
}

console.log('=== BEFORE REQUEST ===')

try {
  const response = await ky.post(`https://api.capgo.app/private/events`, {
    json: payload,
    headers: {
      capgkey: 'your-capgkey-here',
    },
    timeout: 10000, // 10 seconds timeout
    retry: 3,
  }).json()

  console.log('=== SUCCESS - Request completed ===')
  console.log('Response:', response)
  process.exit(0)
} catch (error) {
  console.log('=== CATCH BLOCK REACHED ===')
  console.log('Error type:', error.constructor.name)
  console.log('Error message:', error.message)
  console.log('=== EXITING WITH CODE 0 (Success - error handled) ===')
  process.exit(0)
}

console.log('=== AFTER TRY/CATCH - THIS SHOULD NEVER PRINT ===')
process.exit(1)
