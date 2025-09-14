//
//  WhisperBridge-Bridging-Header.h
//  WhisperBridge
//
//  Bridging header for whisper.cpp C++ integration with Swift
//

#ifndef WHISPER_BRIDGE_BRIDGING_HEADER_H
#define WHISPER_BRIDGE_BRIDGING_HEADER_H

// Import whisper.cpp C API
#ifdef __cplusplus
extern "C" {
#endif

// Basic whisper.h functions for Swift
#include <stdint.h>
#include <stdbool.h>

// Core whisper context and parameters
struct whisper_context;
struct whisper_full_params;

// Model loading and cleanup
struct whisper_context* whisper_init_from_file(const char* path_model);
void whisper_free(struct whisper_context* ctx);

// Transcription parameters
struct whisper_full_params whisper_full_default_params(enum whisper_sampling_strategy strategy);

// Main transcription function
int whisper_full(
    struct whisper_context* ctx,
    struct whisper_full_params params,
    const float* samples,
    int n_samples
);

// Result retrieval
int whisper_full_n_segments(struct whisper_context* ctx);
const char* whisper_full_get_segment_text(struct whisper_context* ctx, int i_segment);
int64_t whisper_full_get_segment_t0(struct whisper_context* ctx, int i_segment);
int64_t whisper_full_get_segment_t1(struct whisper_context* ctx, int i_segment);

// System info
const char* whisper_print_system_info(void);

// Language support
int whisper_lang_max_id(void);
const char* whisper_lang_str(int id);
int whisper_lang_id(const char* lang);

// Available sampling strategies
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY,
    WHISPER_SAMPLING_BEAM_SEARCH,
};

// Helper functions for Swift integration
const char* whisper_bridge_get_system_info(void);
bool whisper_bridge_is_model_loaded(const struct whisper_context* ctx);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_BRIDGE_BRIDGING_HEADER_H