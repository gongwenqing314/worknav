/**
 * 工作导航（StepByStep）辅导员端 - 应用入口
 * 初始化 Vue 3 + Pinia + Router + Element Plus
 */
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'

import App from './App.vue'
import router from './router'
import './styles/index.css'

const app = createApp(App)

// 注册 Pinia 状态管理
const pinia = createPinia()
app.use(pinia)

// 注册路由
app.use(router)

// 注册 Element Plus（中文语言包）
app.use(ElementPlus, {
  locale: zhCn,
  size: 'default'
})

// 全局注册 Element Plus 图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.mount('#app')
