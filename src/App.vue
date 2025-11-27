<template>
  <div :class="{ 'dark': isDark }" class="min-h-screen transition-colors">
    <div class="app-container">
      <router-view />
    </div>
  </div>
</template>

<script setup>
import { useTheme } from './composables/useTheme'

const { isDark } = useTheme()
</script>

<style>
.app-container {
  min-height: 100vh;
  background-color: var(--bg-primary);
  color: var(--text-primary);
}
</style>
