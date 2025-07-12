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
const isCalculateDisabled = ref(true);
const isLoadingRecord = ref(false);

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

// Computed property for calculate button disabled state
const calculateDisabled = computed(() => {
    // Disable if no data or if manually disabled after successful calculation
    return !data.value || data.value.length === 0 || isCalculateDisabled.value;
});

// The Tauri event listener is moved here to directly update the component's state.
useTauriEvent<Record>("record", (e) => {
    isLoadingRecord.value = true;
    data.value = e.inputs;
    target_value.value = e.target_value;
    minValue.value = e.min_value;
    maxValue.value = e.max_value;
    // When a history record is loaded, reset selection and disable calculate button
    selectedKeys.value = [];
    isCalculateDisabled.value = true;
    // Use nextTick to ensure the state is properly set after data update
    setTimeout(() => {
        isLoadingRecord.value = false;
    }, 0);
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

// Watch for changes in table data to enable calculate button
watch(
    () => data.value,
    (_, oldData) => {
        // Only enable calculate button when data changes if we're not loading a record
        // and the change is not from loading a history record
        if (!isLoadingRecord.value && oldData !== undefined) {
            isCalculateDisabled.value = false;
        }
    },
    { deep: true },
);

// All event handler logic is now part of the component itself.
const handleAdd = () => {
    data.value.push({
        key: String(data.value.length + 1),
        name: String(data.value.length + 1),
        volume: 0,
        value: 0,
        modified_volumn: 0,
    });
    // Enable calculate button when new row is added
    isCalculateDisabled.value = false;
};

const handleDel = () => {
    data.value = data.value.filter(
        (item) => !selectedKeys.value.includes(item.key),
    );
    selectedKeys.value = [];
    // Enable calculate button when rows are deleted (if data still exists)
    if (data.value.length > 0) {
        isCalculateDisabled.value = false;
    }
};

const handleSubmit = async () => {
    try {
        await invoke("calc_loading_volumn", {
            inputStr: JSON.stringify(data.value),
        });
        // Disable calculate button after successful calculation
        isCalculateDisabled.value = true;
        emit("completed");
    } catch (error) {
        console.log("calc_loading_volumn with error:", error);
        Modal.error({
            title: "提交失败",
            content: "请确保数据格式正确",
        });
        // Keep calculate button enabled on error
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
        // Enable calculate button when data is imported
        isCalculateDisabled.value = false;
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
                        <template #name="{ record }">
                            <a-input
                                v-model="record.name"
                                style="width: 80px"
                            />
                        </template>
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
                        :disabled="calculateDisabled"
                        >计算</a-button
                    >
                </a-col>
            </a-row>
        </a-col>
    </a-row>
</template>
