# 基于Xillinx FPGA的数字时钟实现

博客地址: [待完善]()

## 特性

- 时钟显示
- 时间调节
- 闹钟设定
- 闹钟响铃（LED闪烁/蜂鸣器）

## 环境

- 正点原子达芬奇FPGA开发板(xc7a35tfgg484)
- Vivado 2022.2
- ModelSim

## 目录结构

- src: 项目的verilog实现
- tb: 项目的测试文件
- cons: 针对每个开发板的约束文件，这里只提供了赛灵思xc7a35t开发板

## 系统原理框图

```mermaid

graph TB
    subgraph 输入
        K0((按键0))
        K1((按键1))
        K2((按键2))
        K3((按键3))
    end
    
    subgraph 输出
        Led0((Led0))
        Led1((Led1))
        Led2((Led2))
        Led3((Led3))

        Seg((数码管))
    end

    subgraph 数据处理部分
        count["计时模块"]
        alarm["闹钟模块"]
        cnt2time["时间转换模块"]
        cntalm2time["闹钟时间转换模块"]
        tune_offset["数据调整偏移量生成模块"]
    end

    subgraph 输出处理部分
        seg_led["七段显示模块"]
        binary2bcd["二进制转BCD模块"]
        seg_data_sel["数据选择模块"]
        led_ctrl["LED控制模块"]
    end
    
    subgraph 状态管理部分
        sys_status_mgr["系统状态管理模块"]
        tune_status_mgr["数据调整状态管理模块"]
    end

    subgraph 输入处理部分
        key_debounce["单按键去抖模块"]
        batch_debounce["按键去抖模块"]
    end

    K0 & K1 & K2 & K3 --> key_debounce
    key_debounce -->|x4| batch_debounce

    count -->|"计时数据(秒)"| cnt2time & alarm
    alarm -->|"闹钟数据(秒)"| cntalm2time
    alarm -->|闹钟触发信号| sys_status_mgr
    
    batch_debounce -->|按键状态| count
    batch_debounce -->|按键状态| tune_status_mgr
    batch_debounce -->|按键状态| sys_status_mgr
    sys_status_mgr -->|系统状态| seg_data_sel
    sys_status_mgr -->|系统状态| led_ctrl
    sys_status_mgr -->|系统状态| count
    tune_status_mgr -->|数据调整状态| tune_offset
    cnt2time -->|"计时数据(时分秒)"| seg_data_sel
    cntalm2time -->|"闹钟数据(时分秒)"| seg_data_sel
    seg_data_sel -->|"选择数据"| binary2bcd
    binary2bcd -->|"bcd数据(时分秒)"| seg_led
    tune_offset -->|调整偏移量| count


    led_ctrl --> Led0 & Led1 & Led2 & Led3
    seg_led --> Seg

```

## 状态转移图

### Sys Status

系统状态

verilog定义如下：
```verilog
parameter S_INIT = 3'd0;
parameter S_NORM = 3'd1;
parameter S_TUNESEL = 3'd2;
parameter S_TUNING  = 3'd3;
parameter S_TUNEALARM = 3'd4;
parameter S_ALARMTUNING = 3'd5;
parameter S_ALARMING = 3'd6;
```

- S_INIT: 初始化状态
- S_NORM: 标准状态，初始化后默认为此状态，时钟正常计时
- S_TUNESEL: 时间调整单位选择状态，可选小时、分钟、秒 (与Tune Status相关)，时钟停止计时
- S_TUNING: 时间调整状态，选择好要调整的为小时/分钟/秒后，进入调整，时钟停止计时
- S_TUNEALARM: 闹钟时间设置单位选择状态，可选小时、分钟、秒 (与Tune Status相关)，时钟正常计时
- S_ALARMTUNING: 闹钟时间设置状态，选择好要设置的为小时/分钟/秒后，进入设置，时钟正常计时
- S_ALARMING: 闹铃触发状态，当时间与设定的闹钟时间相同时进入，此时LED频闪，时钟正常计时

```mermaid

stateDiagram-v2
    [*] --> S_INIT
    S_INIT --> S_NORM: keys == 0000
    S_NORM --> S_TUNESEL: keys == 0001
    S_NORM --> S_TUNEALARM: keys == 1000
    S_NORM --> S_ALARMING: reach_alarm_time == 1
    S_TUNESEL --> S_NORM: keys == K_CANCEL
    S_TUNESEL --> S_TUNING: keys == K_CONFIRM
    S_TUNING --> S_TUNESEL: keys == K_CANCEL
    S_TUNING --> S_TUNESEL: keys == K_CONFIRM
    S_TUNEALARM --> S_NORM: keys == K_CANCEL
    S_TUNEALARM --> S_ALARMTUNING: keys == K_CONFIRM
    S_ALARMTUNING --> S_TUNEALARM: keys == K_CANCEL
    S_ALARMTUNING --> S_TUNEALARM: keys == K_CONFIRM
    S_ALARMING --> S_NORM: |keys

```

### Tune Status

在Sys Status为S_TUNESEL或者S_TUNEALARM时进入，用于选择小时、分钟、秒进行调整/设置。

Verilog定义如下
```verilog
parameter T_NONE = 2'd0;
parameter T_HOUR = 2'd3;
parameter T_MINUTE = 2'd2;
parameter T_SECOND = 2'd1;
```

- T_NONE: 当Sys Status不为S_TUNESEL或者S_TUNEALARM时，将状态置为None
- T_HOUR、T_MINUTE、T_SECOND: 调整/设置小时、分钟、秒，可通过左右移动按键来进行选择

```mermaid

stateDiagram-v2
    [*] --> T_SECOND
    T_SECOND --> T_MINUTE: keys == MV_RIGHT
    T_SECOND --> T_HOUR: keys == MV_LEFT
    T_HOUR --> T_MINUTE: keys == MV_LEFT
    T_MINUTE --> T_HOUR: keys == MV_RIGHT
    T_HOUR --> T_SECOND: keys == MV_RIGHT
    T_MINUTE --> T_SECOND: keys == MV_LEFT

```

## 参考资料
- [正点原子官方开发手册（数码管显示部分）](http://47.111.11.73/docs/boards/fpga/zdyz_dafenqi.html)
