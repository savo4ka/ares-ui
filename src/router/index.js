import { createRouter, createWebHistory } from 'vue-router'
import CreateSecret from '../views/CreateSecret.vue'
import ViewSecret from '../views/ViewSecret.vue'

const routes = [
  {
    path: '/',
    name: 'CreateSecret',
    component: CreateSecret
  },
  {
    path: '/s/:id',
    name: 'ViewSecret',
    component: ViewSecret
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
