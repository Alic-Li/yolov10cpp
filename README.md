# DocLayout-YOLO C++ Inference

This project runs DocLayout-YOLO ONNX layout detection with C++17, OpenCV, and ONNX Runtime.

The executable only supports image inference:

```bash
./yolov10_cpp <model_path> <image_path> [--output_type image|json]
```

The default `image` output saves `result.jpg` in the current working directory. The `json` output writes detections to stdout without rendering an image.

## Dependencies

- CMake 3.10+; CMake 3.19+ for the bundle target
- A C++17 compiler
- OpenCV, with `core`, `imgproc`, and `imgcodecs`
- ONNX Runtime C/C++ library

The tested model is:

https://modelscope.cn/models/AlicLi/rwkv_lightning_cuda/resolve/master/doclayout_yolo_onnx/doclayout_yolo_docstructbench_imgsz1024.onnx

## Linux

Install build tools and OpenCV:

```bash
sudo apt update
sudo apt install -y build-essential cmake libopencv-dev
```

Install ONNX Runtime from an official release, then point CMake to its include and library paths. If ONNX Runtime is installed under `/usr`, build with:

```bash
cmake -S . -B build \
  -DONNXRUNTIME_INCLUDE_DIR=/usr/include/onnxruntime \
  -DONNXRUNTIME_LIBRARY=/usr/lib/libonnxruntime.so

cmake --build build -j$(nproc)
```

Run:

```bash
./build/yolov10_cpp ./doclayout_yolo_docstructbench_imgsz1024.onnx ./test.png
```

Run with JSON output:

```bash
./build/yolov10_cpp ./doclayout_yolo_docstructbench_imgsz1024.onnx ./test.png --output_type json
```

By default, CPU inference uses up to 8 threads. Tune this per machine with:

```bash
YOLOV10_CPP_NUM_THREADS=4 ./build/yolov10_cpp ./doclayout_yolo_docstructbench_imgsz1024.onnx ./test.png
```

Build a portable runtime bundle:

```bash
cmake --build build --target bundle_yolov10_cpp -j$(nproc)
```

The bundle is written to `build/bundle/yolov10_cpp`. Use the generated launcher so the bundled libraries are found first:

```bash
./build/bundle/yolov10_cpp/run_yolov10_cpp.sh ./doclayout_yolo_docstructbench_imgsz1024.onnx ./test.png
```

## macOS

Install dependencies with Homebrew:

```bash
brew install cmake opencv onnxruntime
```

Build:

```bash
cmake -S . -B build \
  -DONNXRUNTIME_INCLUDE_DIR="$(brew --prefix onnxruntime)/include/onnxruntime" \
  -DONNXRUNTIME_LIBRARY="$(brew --prefix onnxruntime)/lib/libonnxruntime.dylib"

cmake --build build -j"$(sysctl -n hw.ncpu)"
```

Run:

```bash
./build/yolov10_cpp ./doclayout_yolo_docstructbench_imgsz1024.onnx ./test.png
```

## Windows

Recommended tools:

- Visual Studio 2022 with "Desktop development with C++"
- CMake
- OpenCV for Windows
- ONNX Runtime for Windows, for example `onnxruntime-win-x64-*`

Example directory layout:

```text
C:\libs\opencv
C:\libs\onnxruntime
```

Configure with PowerShell:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 `
  -DOpenCV_DIR="C:\libs\opencv\build" `
  -DONNXRUNTIME_INCLUDE_DIR="C:\libs\onnxruntime\include" `
  -DONNXRUNTIME_LIBRARY="C:\libs\onnxruntime\lib\onnxruntime.lib"
```

Build:

```powershell
cmake --build build --config Release
```

Run:

```powershell
.\build\Release\yolov10_cpp.exe .\doclayout_yolo_docstructbench_imgsz1024.onnx .\test.png
```

## Notes

- This program performs document layout detection, not OCR.
- The output labels follow DocLayout-YOLO classes such as `title`, `plain text`, `figure`, and `table`.
- The ONNX model input size is read from the model when possible.
