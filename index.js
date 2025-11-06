
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
// Ensure we read response to ensure no memory leaks
  error.response?.arrayBuffer();
  console.log('=== CATCH BLOCK REACHED ===')
  console.log('Error type:', error.constructor.name)
  console.log('Error message:', error.message)
  console.log('Error status code:', error.response?.status)
  console.log('Process exit code before exit():', process.exitCode)
  console.log('=== CALLING process.exit(0) ===')
  process.exitCode = 0
  console.log('Process exit code after setting to 0:', process.exitCode)
  process.exit(0)
}

console.log('=== AFTER TRY/CATCH - THIS SHOULD NEVER PRINT ===')
process.exit(1)
