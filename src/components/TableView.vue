<script setup lang="ts">
import { computed, ref, watch, defineEmits } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { TableRowSelection, Modal } from "@arco-design/web-vue";
import { useTauriEvent, Record, InputData } from "@/utils/useTauriEvent";

// This component now accepts a 'recordIndex' to know which record to display.
const props = defineProps<{
    recordIndex: string;
}>();

const emit = defineEmits(["completed"]);

// All state related to the table is now managed within this component.
const data = ref<InputData[]>([]);
const selectedKeys = ref<string[]>([]);
const target_value = ref(0);
const minValue = ref(0);
const maxValue = ref(0);

const slide_disabled = computed(() => {
    // The slider is disabled if no data exists or if every item's
    // 'modified_volumn' is 0, null, or undefined.
    if (!data.value || data.value.length === 0) {
        return true;
    }
    // The .every() method checks if all elements in the array pass the test.
    // The test '!item.modified_volumn' is true for 0, null, and undefined.
    return data.value.every((item) => !item.modified_volumn);
});

// The Tauri event listener is moved here to directly update the component's state.
useTauriEvent<Record>("record", (e) => {
    data.value = e.inputs;
    target_value.value = e.target_value;
    minValue.value = e.min_value;
    maxValue.value = e.max_value;
    // When a new record is loaded, reset selection and disable the slider.
    selectedKeys.value = [];
});

// Watch for changes in the recordIndex prop and fetch the corresponding record.
watch(
    () => props.recordIndex,
    (newIndex) => {
        if (newIndex) {
            invoke("get_record", { index: parseInt(newIndex, 10) });
        }
    },
    { immediate: true },
); // 'immediate: true' ensures it runs on component mount.

// All event handler logic is now part of the component itself.
const handleAdd = () => {
    data.value.push({
        key: String(data.value.length + 1),
        name: String(data.value.length + 1),
        volume: 0,
        value: 0,
        modified_volumn: 0,
    });
};

const handleDel = () => {
    data.value = data.value.filter(
        (item) => !selectedKeys.value.includes(item.key),
    );
    selectedKeys.value = [];
};

const handleSubmit = async () => {
    try {
        await invoke("calc_loading_volumn", {
            inputStr: JSON.stringify(data.value),
        });
        emit("completed");
    } catch (error) {
        console.log("calc_loading_volumn with error:", error);
        Modal.error({
            title: "提交失败",
            content: "请确保数据格式正确",
        });
    }
};

const handleValueChange = (value: number) => {
    invoke("update_loading_volumn", {
        targetValue: value,
    });
};

const fetchClipboardData = async () => {
    try {
        const resp = await invoke<string>("read_clipboard");
        data.value = JSON.parse(resp) as InputData[];
    } catch (error) {
        console.log("read clipboard with error:", error);
        Modal.error({
            title: "导入失败",
            content: "请确保剪贴板中有正确的数据",
        });
    }
};

// Static definitions that were moved from Home.vue
const editable_columns = [
    {
        title: "样品",
        dataIndex: "name",
        slotName: "name",
    },
    {
        title: "内参上样量",
        dataIndex: "volumn",
        slotName: "volumn",
    },
    {
        title: "内参灰度值",
        dataIndex: "value",
        slotName: "value",
    },
    {
        title: "调整上样量",
        dataIndex: "modified_volumn",
        slotName: "modified_volumn",
    },
];

const rowSelection: TableRowSelection = {
    type: "checkbox",
    showCheckedAll: true,
};
</script>

<template>
    <a-row justify="center" style="margin-bottom: 5px; margin-top: 40px">
        <a-col>
            <a-space size="mini" direction="vertical" fill>
                <!-- 头部按钮 -->
                <a-row
                    justify="space-between"
                    align="center"
                    style="padding: 0 8px"
                >
                    <a-col :span="12">
                        <a-space align="start" size="mini">
                            <a-tooltip content="添加" mini>
                                <a-button
                                    size="mini"
                                    type="outline"
                                    @click="handleAdd"
                                    ><template #icon><icon-plus /></template
                                ></a-button>
                            </a-tooltip>
                            <a-tooltip content="从剪贴板导入" mini>
                                <a-button
                                    type="outline"
                                    size="mini"
                                    @click="fetchClipboardData"
                                >
                                    <template #icon><icon-import /></template>
                                </a-button>
                            </a-tooltip>
                            <a-tooltip content="删除" mini>
                                <a-button
                                    type="outline"
                                    status="danger"
                                    size="mini"
                                    :disabled="selectedKeys.length === 0"
                                    @click="handleDel"
                                    ><template #icon><icon-delete /></template
                                ></a-button>
                            </a-tooltip>
                        </a-space>
                    </a-col>
                    <a-col :span="12" style="text-align: right">
                        <a-slider
                            v-model="target_value"
                            :min="minValue"
                            :max="maxValue"
                            style="
                                display: inline-flex;
                                height: 25px;
                                width: 40%;
                            "
                            :disabled="slide_disabled"
                            :show-tooltip="false"
                            @change="handleValueChange(target_value)"
                        />
                    </a-col>
                </a-row>
                <!-- 表格 -->
                <a-row>
                    <a-table
                        :columns="editable_columns"
                        :data="data"
                        :pagination="false"
                        :row-selection="rowSelection"
                        v-model:selectedKeys="selectedKeys"
                        style="width: 100%"
                    >
                        <template #volumn="{ record }">
                            <a-input-number
                                v-model="record.volumn"
                                :hide-button="true"
                                style="width: 100px"
                            />
                        </template>
                        <template #value="{ record }">
                            <a-input-number
                                v-model="record.value"
                                :hide-button="true"
                                style="width: 110px"
                            />
                        </template>
                    </a-table>
                </a-row>
            </a-space>
            <a-row align="end" justify="end" style="margin-top: 20px">
                <a-col :span="4">
                    <a-button
                        type="primary"
                        long
                        @click="handleSubmit"
                        :disabled="data.length === 0"
                        >计算</a-button
                    >
                </a-col>
            </a-row>
        </a-col>
    </a-row>
</template>
