<template>
  <div class="page-container">
    <header class="header">
      <div class="logo" @click="goHome">
        <svg class="logo-icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <path d="M12 6v6l4 2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
        <h1 class="logo-text">Ares</h1>
      </div>
      <button @click="toggleTheme" class="theme-toggle" aria-label="Toggle theme">
        <svg v-if="!isDark" class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3"/>
          <line x1="12" y1="21" x2="12" y2="23"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
          <line x1="1" y1="12" x2="3" y2="12"/>
          <line x1="21" y1="12" x2="23" y2="12"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
        </svg>
        <svg v-else class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
      </button>
    </header>

    <main class="content">
      <!-- Loading State -->
      <div v-if="isLoading" class="state-container">
        <div class="spinner"></div>
        <h2 class="state-title">Загрузка секрета...</h2>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="state-container">
        <div class="error-icon">
          <svg class="icon-large" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
        </div>
        <h2 class="state-title">{{ errorTitle }}</h2>
        <p class="state-description">{{ error }}</p>
        <button @click="goHome" class="action-button">
          Создать новый секрет
        </button>
      </div>

      <!-- Success State -->
      <div v-else-if="secretContent" class="secret-container">
        <h2 class="title">Секретное сообщение</h2>

        <div class="secret-box">
          <div class="secret-content">{{ secretContent }}</div>
        </div>

        <button @click="copySecret" class="copy-button">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
          </svg>
          Копировать секрет
        </button>

        <!-- Toast notification -->
        <transition name="toast">
          <div v-if="showToast" class="toast">
            <svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M20 6L9 17l-5-5"/>
            </svg>
            Секрет успешно скопирован!
          </div>
        </transition>

        <div class="warning-box">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
            <line x1="12" y1="9" x2="12" y2="13"/>
            <line x1="12" y1="17" x2="12.01" y2="17"/>
          </svg>
          <div>
            <strong>Важно:</strong> Это сообщение было прочитано и больше недоступно.
            Убедитесь, что вы сохранили его в безопасном месте.
          </div>
        </div>

        <div class="meta-info">
          <div class="meta-item">
            <span class="meta-label">Создано:</span>
            <span class="meta-value">{{ formatDate(createdAt) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Истекает:</span>
            <span class="meta-value">{{ formatDate(expiresAt) }}</span>
          </div>
        </div>

        <button @click="goHome" class="action-button secondary">
          Создать новый секрет
        </button>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useTheme } from '../composables/useTheme'
import { secretsApi } from '../services/api'

const route = useRoute()
const router = useRouter()
const { isDark, toggleTheme } = useTheme()

const secretContent = ref('')
const createdAt = ref('')
const expiresAt = ref('')
const isLoading = ref(true)
const error = ref('')
const errorTitle = ref('')
const showToast = ref(false)

onMounted(async () => {
  const secretId = route.params.id

  if (!secretId) {
    error.value = 'Неверная ссылка'
    errorTitle.value = 'Ошибка'
    isLoading.value = false
    return
  }

  try {
    const result = await secretsApi.getSecret(secretId)
    secretContent.value = result.content
    createdAt.value = result.created_at
    expiresAt.value = result.expires_at
  } catch (err) {
    if (err.response?.status === 404) {
      errorTitle.value = 'Секрет не найден'
      error.value = 'Этот секрет не существует или уже был прочитан.'
    } else if (err.response?.status === 410) {
      errorTitle.value = 'Секрет недоступен'
      error.value = 'Этот секрет уже был прочитан или истёк срок его действия.'
    } else {
      errorTitle.value = 'Ошибка'
      error.value = err.response?.data?.error || 'Не удалось загрузить секрет'
    }
    console.error('Error fetching secret:', err)
  } finally {
    isLoading.value = false
  }
})

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('ru-RU', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const copySecret = async () => {
  try {
    // Try modern clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(secretContent.value)
    } else {
      // Fallback for older browsers or insecure contexts
      const textArea = document.createElement('textarea')
      textArea.value = secretContent.value
      textArea.style.position = 'fixed'
      textArea.style.left = '-999999px'
      textArea.style.top = '-999999px'
      document.body.appendChild(textArea)
      textArea.focus()
      textArea.select()
      document.execCommand('copy')
      textArea.remove()
    }

    showToast.value = true
    setTimeout(() => {
      showToast.value = false
    }, 3000)
  } catch (err) {
    console.error('Failed to copy:', err)
    alert('Не удалось скопировать секрет. Попробуйте выделить текст вручную.')
  }
}

const goHome = () => {
  router.push('/')
}
</script>

<style scoped>
.page-container {
  min-height: 100vh;
  background-color: var(--bg-primary);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid var(--border-primary);
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  transition: opacity 0.2s;
}

.logo:hover {
  opacity: 0.8;
}

.logo-icon {
  width: 2rem;
  height: 2rem;
  color: var(--accent-primary);
}

.logo-text {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
}

.theme-toggle {
  width: 2.5rem;
  height: 2.5rem;
  border: none;
  background: transparent;
  color: var(--text-secondary);
  cursor: pointer;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.theme-toggle:hover {
  background-color: var(--bg-tertiary);
  color: var(--text-primary);
}

.icon {
  width: 1.5rem;
  height: 1.5rem;
  stroke-width: 2;
}

.icon-large {
  width: 4rem;
  height: 4rem;
  stroke-width: 2;
}

.content {
  max-width: 60rem;
  margin: 0 auto;
  padding: 3rem 2rem;
}

.state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  min-height: 60vh;
  gap: 1.5rem;
}

.spinner {
  width: 3rem;
  height: 3rem;
  border: 3px solid var(--border-primary);
  border-top-color: var(--accent-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-icon {
  color: #EF4444;
}

.dark .error-icon {
  color: #F87171;
}

.state-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
}

.state-description {
  font-size: 1rem;
  color: var(--text-secondary);
  margin: 0;
  max-width: 32rem;
}

.secret-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.title {
  font-size: 2rem;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
}

.secret-box {
  position: relative;
  padding: 1.5rem;
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-primary);
  border-radius: 0.5rem;
}

.secret-content {
  color: var(--text-primary);
  font-size: 1rem;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

.copy-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  background-color: var(--accent-primary);
  border: none;
  border-radius: 0.5rem;
  color: var(--text-button);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  align-self: flex-start;
}

.copy-button:hover {
  background-color: var(--accent-hover);
}

.copy-button:active {
  transform: scale(0.98);
  background-color: var(--bg-button);
}

/* Toast notification */
.toast {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background-color: #10B981;
  color: white;
  border-radius: 0.5rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  font-size: 0.875rem;
  font-weight: 500;
  z-index: 1000;
}

.dark .toast {
  background-color: #059669;
}

.toast-icon {
  width: 1.25rem;
  height: 1.25rem;
  stroke-width: 2.5;
}

/* Toast animation */
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateY(1rem);
}

.toast-leave-to {
  opacity: 0;
  transform: translateY(0.5rem);
}

.warning-box {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  background-color: #FEF3C7;
  border: 1px solid #FCD34D;
  border-radius: 0.5rem;
  color: #92400E;
  font-size: 0.875rem;
  line-height: 1.5;
}

.dark .warning-box {
  background-color: #78350F;
  border-color: #92400E;
  color: #FEF3C7;
}

.warning-box svg {
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.meta-info {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  padding: 1rem;
  background-color: var(--bg-secondary);
  border-radius: 0.5rem;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.meta-label {
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.meta-value {
  font-size: 0.875rem;
  color: var(--text-primary);
}

.action-button {
  padding: 0.75rem 1.5rem;
  background-color: var(--bg-button);
  border: none;
  border-radius: 0.5rem;
  color: var(--text-button);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  align-self: flex-start;
}

.action-button:hover {
  background-color: var(--bg-button-hover);
}

.action-button.secondary {
  background-color: var(--accent-primary);
  color: var(--text-button);
}

.action-button.secondary:hover {
  background-color: var(--accent-hover);
}
</style>
