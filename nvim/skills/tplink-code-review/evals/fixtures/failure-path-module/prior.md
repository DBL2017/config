评审状态：已完成
结论：需要修改

- [Medium] upload.c:18-21,35-42：打开输出文件失败仍返回成功，调用方删除待处理数据
原因：fopen 失败时 result 仍为0；调用方忽略 save_report 返回值并删除 fixture-pending。
建议：打开失败返回错误；调用方仅在处理成功后删除待处理文件。
