#include "./ia/inference.h"
#include <iomanip>
#include <iostream>
#include <opencv2/opencv.hpp>
#include <stdexcept>
#include <string>

namespace
{
enum class OutputType
{
    Image,
    Json
};

void printUsage(const char *program_name)
{
    std::cerr << "Usage: " << program_name << " <model_path> <image_path> [--output_type image|json]" << std::endl;
}

std::string escapeJsonString(const std::string &value)
{
    std::string escaped;
    escaped.reserve(value.size());

    for (char ch : value)
    {
        switch (ch)
        {
        case '"':
            escaped += "\\\"";
            break;
        case '\\':
            escaped += "\\\\";
            break;
        case '\b':
            escaped += "\\b";
            break;
        case '\f':
            escaped += "\\f";
            break;
        case '\n':
            escaped += "\\n";
            break;
        case '\r':
            escaped += "\\r";
            break;
        case '\t':
            escaped += "\\t";
            break;
        default:
            escaped += ch;
            break;
        }
    }

    return escaped;
}

void writeDetectionsJson(const std::vector<Detection> &detections)
{
    std::cout << "[\n";
    for (size_t i = 0; i < detections.size(); ++i)
    {
        const Detection &detection = detections[i];
        std::cout << "  {\n"
                  << "    \"class\": \"" << escapeJsonString(detection.class_name) << "\",\n"
                  << "    \"confidence\": " << std::fixed << std::setprecision(6) << detection.confidence << ",\n"
                  << "    \"bbox\": ["
                  << detection.bbox.x << ", "
                  << detection.bbox.y << ", "
                  << detection.bbox.width << ", "
                  << detection.bbox.height << "]\n"
                  << "  }";
        if (i + 1 < detections.size())
        {
            std::cout << ",";
        }
        std::cout << "\n";
    }
    std::cout << "]\n";
}
}

int main(int argc, char *argv[])
{
    if (argc != 3 && argc != 5)
    {
        printUsage(argv[0]);
        return 1;
    }

    std::string model_path = argv[1];
    std::string image_path = argv[2];
    OutputType output_type = OutputType::Image;

    if (argc == 5)
    {
        std::string option_name = argv[3];
        std::string option_value = argv[4];
        if (option_name != "--output_type")
        {
            printUsage(argv[0]);
            return 1;
        }

        if (option_value == "json")
        {
            output_type = OutputType::Json;
        }
        else if (option_value == "image")
        {
            output_type = OutputType::Image;
        }
        else
        {
            printUsage(argv[0]);
            return 1;
        }
    }

    try
    {
        InferenceEngine engine(model_path);
    
        cv::Mat image = cv::imread(image_path);
        if (image.empty())
        {
            throw std::runtime_error("Could not read the image");
        }

        int orig_width = image.cols;
        int orig_height = image.rows;
        std::vector<float> input_tensor_values = engine.preprocessImage(image );

        std::vector<float> results = engine.runInference(input_tensor_values);

        float confidence_threshold = 0.2;

        std::vector<Detection> detections = engine.filterDetections(results, confidence_threshold, engine.input_shape[2], engine.input_shape[3], orig_width, orig_height);

        if (output_type == OutputType::Json)
        {
            writeDetectionsJson(detections);
            return 0;
        }

        cv::Mat output = engine.draw_labels(image, detections);
        cv::imwrite("result.jpg", output);
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
