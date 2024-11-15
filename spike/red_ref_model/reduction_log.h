#ifndef REDUCTION_LOG_H
#define REDUCTION_LOG_H

#include <fstream>
#include <string>

#include "reduction_defines.h"
#include "reduction_types.h"

using namespace std;

class reduction_log {
   private:
    string ins_info;
    string log;
    string vs;
    string vmask;
    string path;
    vector<string> unord_log_lane;
    vector<string> unord_log_lane_accum;
    string final_res;
    ofstream out;

   public:
    /**
     * @brief Sets the path to the file which the final log will be dumped into.
     *
     * @param path Path to the file.
     */
    void set_path(string path);

    /**
     * @brief Function to add all the information that will be outputed with the
     * log.
     *
     * @param scalar The scalar used in the reduction instruction.
     * @param hex_ins The instruction code in hexadecimal.
     * @param ins The instr struct containing all the information from the
     * instruction.
     * @param vl The vector length.
     * @param sew The standard element width.
     */
    void add_ins_info(uint64_t scalar, uint64_t hex_ins, instr ins, uint32_t vl,
                      uint32_t sew);

    /**
     * @brief Adds to the log all the elements from the source vector register.
     *
     * @param vs The source vector register.
     * @param b_sew The standard element width in bytes.
     * @param vl The vector length.
     */
    void set_vs(vector<uint8_t> &vs, uint32_t b_sew, uint32_t vl);

    /**
     * @brief Adds to the log all the elements from the mask register.
     *
     * @param vmask The vector mask register.
     * @param b_sew The standard element width in bytes.
     * @param vl The vector length
     */
    void set_vmask(vector<uint8_t> &vmask, uint32_t b_sew, uint32_t vl);

    /**
     * @brief Function to add one of the resulting values from a lane.
     *
     * @param res The value resulting from the lane.
     * @param lane The lane number.
     * @param b_sew The standard element width in bytes.
     */
    void add_lane_log(uint64_t res, int lane, uint32_t b_sew);

    /**
     * @brief Function to add the elements in the order that are being used in
     * an ordered reduction.
     *
     * @param val The value of the element that is being used.
     * @param b_vsew The standard element width in bytes.
     */
    void add_ord_log(uint64_t val, uint32_t b_vsew);

    /**
     * @brief Funtion to add the elements in the order that are being used in an
     * ordered reduction when the actual element is masked
     *
     * @param val The value of the element that is being used.
     * @param b_vsew The standard element width in bytes.
     */
    void add_ord_mask_log(uint64_t val, uint32_t b_vsew);

    /**
     * @brief Writes the whole log into the path specified.
     *
     */
    void write_log();

    /**
     * @brief Adds an element to the logging of the elements used for the
     * unordered reduction, by lane.
     *
     * @param val The value to be logged.
     * @param b_vsew The standard element width in bytes.
     * @param lane_num The number of the lane which is operating with val.
     * @param masking Boolean that tells if the actual element is masked.
     */
    void add_unord_lane_log(uint64_t val, uint32_t b_vsew, uint64_t lane_num,
                            bool masking);

    /**
     * @brief Adds final value of accum to the logging, by lane
     *
     * @param val The value to be logged.
     * @param b_vsew The standard element width in bytes.
     * @param lane_num The number of the lane which is operating with val.
     * @param lane_num The number of the accum which is operating with val.
     */
    void add_unord_lane_accum_log(uint64_t val, uint32_t b_vsew, uint64_t lane_num,
                            uint64_t accum_num);

    /**
     * @brief Adds final value of reduction
     *
     * @param val The value to be logged.
     * @param b_vsew The standard element width in bytes.
     */
    void add_final_res_log(uint64_t val, uint32_t b_vsew);

   private:
    /**
     * @brief Converts a given value to hexadecimal with the given size.
     *
     * @param a The value to be converted.
     * @param size The size of the element.
     * @return string
     */
    string to_hex(uint64_t a, uint64_t size);

    /**
     * @brief Generates en element from the byte-sized elemet array.
     *
     * @param start The index on which the element begins.
     * @param v The byte-sized element array.
     * @param sew The standard element width.
     * @return uint64_t
     */
    uint64_t get_elem(int start, const vector<uint8_t> &v, uint32_t sew);

    /**
     * @brief Clears all the strings.
     *
     */
    void clear();
};

#endif
