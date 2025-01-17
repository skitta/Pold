import { createApp } from "vue";
// import ArcoVue from "@arco-design/web-vue";
import App from "./App.vue";
// import "@arco-design/web-vue/dist/arco.css";

const app = createApp(App);

// app.use(ArcoVue, {
//   // 用于改变使用组件时的前缀名称
//   componentPrefix: "arco",
// });
app.mount("#app");
