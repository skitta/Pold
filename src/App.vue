<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const transitionName = ref("slide-forward");

// 根据路由历史判断滑动方向
router.beforeEach((to, from) => {
    transitionName.value =
        to.meta.index > from.meta.index ? "slide-forward" : "slide-back";
});
</script>

<template>
    <main class="container">
        <router-view v-slot="{ Component }">
            <transition :name="transitionName" mode="out-in">
                <component :is="Component" :key="$route.path" />
            </transition>
        </router-view>
    </main>
</template>

<style>
:root {
    font-family: Inter, Avenir, Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 24px;
    font-weight: 400;

    color: #0f0f0f;
    background-color: #f6f6f6;

    font-synthesis: none;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    -webkit-text-size-adjust: 100%;
}

.container {
    margin: 0;
    padding-top: 10vh;
    padding-bottom: 5vh;
    display: flex;
    flex-direction: column;
    /* justify-content: center; */
    /* text-align: center; */
}
</style>

<style scoped>
/* 前进动画 */
.slide-forward-enter-from {
    transform: translateX(100%);
    opacity: 0;
}
.slide-forward-leave-to {
    transform: translateX(-30%);
    opacity: 0;
}

/* 后退动画 */
.slide-back-enter-from {
    transform: translateX(-30%);
    opacity: 0;
}
.slide-back-leave-to {
    transform: translateX(100%);
    opacity: 0;
}

.slide-forward-enter-active,
.slide-forward-leave-active,
.slide-back-enter-active,
.slide-back-leave-active {
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: absolute;
    width: 100%;
}
</style>
