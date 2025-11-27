<template>
  <div class="page-container">
    <header class="header">
      <div class="logo">
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

    <nav class="tabs">
      <button class="tab active">Сообщение</button>
    </nav>

    <main class="content">
      <h2 class="title">Введите секретное сообщение</h2>

      <div class="form">
        <div class="form-group">
          <label class="label">Сообщение</label>
          <textarea
            v-model="secretContent"
            class="textarea"
            placeholder="Напишите или вставьте что-то"
            rows="8"
          ></textarea>
          <div class="textarea-actions">
            <button
              v-if="secretContent"
              @click="clearContent"
              class="clear-button"
              aria-label="Clear content"
            >
              <svg class="icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <line x1="18" y1="6" x2="6" y2="18"/>
                <line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
        </div>

        <div class="form-group">
          <label class="label">Ссылка</label>
          <div class="link-input-wrapper">
            <input
              v-model="generatedUrl"
              type="text"
              class="input"
              readonly
              :placeholder="generatedUrl || ''"
            />
            <button
              v-if="generatedUrl"
              @click="copyToClipboard"
              class="copy-icon-button"
              aria-label="Copy URL"
            >
              <svg class="icon-small" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- Toast notification -->
        <transition name="toast">
          <div v-if="showToast" class="toast">
            <svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M20 6L9 17l-5-5"/>
            </svg>
            Ссылка скопирована!
          </div>
        </transition>

        <div class="expiration-buttons">
          <button
            v-for="hours in [24, 48, 72]"
            :key="hours"
            @click="selectedExpiration = hours"
            :class="['expiration-button', { active: selectedExpiration === hours }]"
          >
            {{ hours }} часа
          </button>
          <button
            @click="createSecret"
            class="action-button"
            :disabled="!secretContent || isLoading"
          >
            {{ isLoading ? 'Создание...' : 'Создать ссылку' }}
          </button>
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useTheme } from '../composables/useTheme'
import { secretsApi } from '../services/api'

const { isDark, toggleTheme } = useTheme()

const secretContent = ref('')
const selectedExpiration = ref(72)
const generatedUrl = ref('')
const isLoading = ref(false)
const showToast = ref(false)
const error = ref('')

const clearContent = () => {
  secretContent.value = ''
  generatedUrl.value = ''
  error.value = ''
}

const createSecret = async () => {
  if (!secretContent.value.trim()) {
    error.value = 'Пожалуйста, введите сообщение'
    return
  }

  isLoading.value = true
  error.value = ''

  try {
    const result = await secretsApi.createSecret(
      secretContent.value,
      selectedExpiration.value
    )

    // Generate full URL
    const baseUrl = window.location.origin
    generatedUrl.value = `${baseUrl}/s/${result.id}`
  } catch (err) {
    error.value = err.response?.data?.error || 'Ошибка при создании секрета'
    console.error('Error creating secret:', err)
  } finally {
    isLoading.value = false
  }
}

const copyToClipboard = async () => {
  try {
    // Try modern clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(generatedUrl.value)
    } else {
      // Fallback for older browsers or insecure contexts
      const textArea = document.createElement('textarea')
      textArea.value = generatedUrl.value
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
    alert('Не удалось скопировать ссылку. Попробуйте выделить текст вручную.')
  }
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

.icon-small {
  width: 1.25rem;
  height: 1.25rem;
  stroke-width: 2;
}

.tabs {
  padding: 0 2rem;
  border-bottom: 1px solid var(--border-primary);
}

.tab {
  padding: 1rem 0;
  background: none;
  border: none;
  color: var(--text-secondary);
  font-size: 0.875rem;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  margin-right: 2rem;
}

.tab.active {
  color: var(--text-primary);
  border-bottom-color: var(--accent-primary);
}

.content {
  max-width: 60rem;
  margin: 0 auto;
  padding: 3rem 2rem;
}

.title {
  font-size: 2rem;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 2rem;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  position: relative;
}

.label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-primary);
}

.textarea {
  width: 100%;
  padding: 1rem;
  background-color: var(--bg-input);
  border: 1px solid var(--border-primary);
  border-radius: 0.5rem;
  color: var(--text-primary);
  font-family: inherit;
  font-size: 1rem;
  resize: vertical;
  transition: all 0.2s;
}

.textarea:focus {
  outline: none;
  border-color: var(--border-focus);
}

.textarea::placeholder {
  color: var(--text-tertiary);
}

.textarea-actions {
  position: absolute;
  top: 2.5rem;
  right: 0.5rem;
  display: flex;
  gap: 0.5rem;
}

.clear-button,
.copy-icon-button {
  width: 2rem;
  height: 2rem;
  padding: 0.25rem;
  background-color: var(--bg-secondary);
  border: none;
  border-radius: 0.375rem;
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.clear-button:hover,
.copy-icon-button:hover {
  background-color: var(--bg-tertiary);
  color: var(--text-primary);
}

.copy-icon-button:active {
  background-color: var(--accent-primary);
  color: var(--text-button);
  transform: scale(0.92);
}

.input {
  width: 100%;
  padding: 0.75rem 3rem 0.75rem 1rem;
  background-color: var(--bg-input);
  border: 1px solid var(--border-primary);
  border-radius: 0.5rem;
  color: var(--text-primary);
  font-family: inherit;
  font-size: 1rem;
  transition: all 0.2s;
}

.input:focus {
  outline: none;
  border-color: var(--border-focus);
}

.link-input-wrapper {
  position: relative;
}

.link-input-wrapper .copy-icon-button {
  position: absolute;
  right: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
}

.expiration-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.expiration-button {
  padding: 0.75rem 1.5rem;
  background-color: var(--bg-secondary);
  border: 2px solid var(--border-primary);
  border-radius: 0.5rem;
  color: var(--text-primary);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.expiration-button:hover {
  border-color: var(--border-secondary);
  background-color: var(--bg-tertiary);
}

.expiration-button.active {
  background-color: var(--accent-primary);
  border-color: var(--accent-primary);
  color: var(--text-button);
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
}

.action-button:hover:not(:disabled) {
  background-color: var(--bg-button-hover);
}

.action-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-button.secondary {
  background-color: var(--accent-primary);
  color: var(--text-button);
}

.action-button.secondary:hover {
  background-color: var(--accent-hover);
}

.error-message {
  padding: 1rem;
  background-color: #FEE2E2;
  border: 1px solid #FCA5A5;
  border-radius: 0.5rem;
  color: #991B1B;
  font-size: 0.875rem;
}

.dark .error-message {
  background-color: #7F1D1D;
  border-color: #991B1B;
  color: #FEE2E2;
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
</style>
