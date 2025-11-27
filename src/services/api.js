import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json'
  }
})

export const secretsApi = {
  /**
   * Create a new secret
   * @param {string} content - Secret content
   * @param {number} expirationHours - Expiration time (24, 48, or 72 hours)
   * @returns {Promise<{id: string, url: string, expires_at: string}>}
   */
  async createSecret(content, expirationHours) {
    const response = await api.post('/secrets', {
      content,
      expiration_hours: expirationHours
    })
    return response.data
  },

  /**
   * Get a secret by ID (can only be read once)
   * @param {string} id - Secret ID
   * @returns {Promise<{content: string, expires_at: string, created_at: string}>}
   */
  async getSecret(id) {
    const response = await api.get(`/secrets/${id}`)
    return response.data
  },

  /**
   * Check API health
   * @returns {Promise<{status: string}>}
   */
  async health() {
    const response = await api.get('/health')
    return response.data
  }
}

export default api
