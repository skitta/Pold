import { createRouter, createWebHistory, RouteRecordRaw } from "vue-router";
import Home from "../views/Home.vue";

declare module "vue-router" {
  interface RouteMeta {
    index: number;
  }
}

// 定义路由类型
const routes: Array<RouteRecordRaw> = [
  {
    path: "/",
    name: "Home",
    meta: { index: 0 },
    component: Home,
  },
  {
    path: "/about",
    name: "About",
    meta: { index: 1 },
    component: () => import("../views/About.vue"),
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

export default router;
