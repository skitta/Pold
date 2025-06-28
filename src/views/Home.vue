<script setup lang="ts">
import { onMounted, ref } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { useRouter } from "vue-router";
import { useTauriEvent } from "@/utils/useTauriEvent";
import TableView from "@/components/TableView.vue";

//左侧菜单 index
const selectedMenuIndex = ref(["0"]);
const menuItems = ref<string[]>([]);
const disableCreate = ref(false);

useTauriEvent<string[]>("history", (e) => {
    menuItems.value = e;
});

onMounted(async () => {
    await invoke("get_history");
    await invoke("get_record", { index: 0 });
});

const handleCreate = () => {
    invoke("create_record");
    selectedMenuIndex.value = ["0"];
    disableCreate.value = true;
};

const handleCompleted = () => {
    disableCreate.value = false;
};

const handleClear = () => {
    invoke("clear_history");
    disableCreate.value = false;
};

const handleMenuItemClick = (key: string) => {
    console.log("handleMenuItemClick", key);
    console.log("menuIndex", selectedMenuIndex);
    invoke("get_record", { index: parseInt(key) });
    selectedMenuIndex.value = [key];
};

const router = useRouter();
const handleHelp = () => {
    router.push({ name: "About" });
};
</script>

<template>
    <a-layout class="layout">
        <a-layout-sider>
            <div class="logo">
                <h1>Pold</h1>
            </div>
            <div class="sider-button">
                <a-button
                    type="primary"
                    @click="handleCreate"
                    long
                    :disabled="disableCreate"
                >
                    新记录
                </a-button>
            </div>
            <a-menu
                :selected-keys="selectedMenuIndex"
                :style="{ width: '100%' }"
                @menu-item-click="handleMenuItemClick"
            >
                <a-menu-item
                    v-for="(item, index) in menuItems"
                    :key="index.toString()"
                >
                    {{ item }}
                </a-menu-item>
            </a-menu>
            <div class="sider-button">
                <a-button
                    type="dashed"
                    status="danger"
                    @click="handleClear"
                    long
                    :disabled="menuItems.length === 0"
                >
                    清除所有记录
                </a-button>
            </div>
        </a-layout-sider>

        <a-layout>
            <a-layout-header>
                <a-page-header
                    title="Western Blot"
                    subtitle="上样修正计算器"
                    :show-back="false"
                    :style="{ background: 'var(--color-bg-2)' }"
                >
                    <template #extra>
                        <a-button
                            size="mini"
                            type="outline"
                            shape="round"
                            @click="handleHelp"
                        >
                            <template #icon>
                                <icon-question />
                            </template>
                        </a-button>
                    </template>
                </a-page-header>
            </a-layout-header>
            <a-layout style="padding: 0 24px">
                <a-layout-content>
                    <TableView
                        v-if="menuItems.length > 0"
                        :record-index="selectedMenuIndex[0]"
                        @completed="handleCompleted"
                    />
                    <a-empty
                        v-else
                        style="margin-top: 25vh"
                        description="No data available"
                    />
                </a-layout-content>
            </a-layout>
        </a-layout>
    </a-layout>
</template>

<style scoped>
.layout {
    height: 100%;
    background: var(--color-fill-2);
    border: 1px solid var(--color-border);
}

.layout :deep(.arco-layout-sider) {
    display: flex;
    flex-direction: column;
}

.layout :deep(.arco-menu) {
    flex-grow: 1;
    overflow-y: auto;
    overflow-x: hidden;
    height: calc(100vh - 184px);
}

.layout :deep(.arco-layout-sider) .logo {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 48px;
    margin: 12px 8px;
    background: rgba(255, 255, 255, 0.2);
}
.layout :deep(.arco-layout-sider-light) .logo {
    background: var(--color-fill-2);
}

.layout .logo h1 {
    font-style: italic;
    font-family: "Brush Script MT";
}

.layout .sider-button {
    margin: 12px 8px;
}

.fit-bottom {
    position: absolute;
    bottom: 0;
}
</style>
