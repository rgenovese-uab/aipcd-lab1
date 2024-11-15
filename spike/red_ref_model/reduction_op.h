#ifndef REDUCTION_OP_H
#define REDUCTION_OP_H

#include <vector>

#include "reduction_defines.h"
#include "reduction_log.h"
#include "reduction_types.h"

using namespace std;

class reduction_op {
   private:
    reduction_log red_log;
    // vsew in bits
    uint8_t vsew;
    // vsew in bytes
    uint8_t b_vsew;
    uint32_t vl;
    uint64_t scalar;
    // source vector
    vector<uint8_t> vs;
    // mask vector
    vector<uint8_t> vmask;
    instr red_ins;
    uint32_t frm;

    uint8_t lane_num;
    uint8_t accum_num_fp;
    uint8_t accum_num_int;
    uint8_t accum_num;

    uint_fast8_t fflags;

    int verb_lvl;
    int act_verb_lvl;

    bool tree_merge_enable_intra;
    bool tree_merge_enable_inter;

   public:

    /**
     * @brief Converts a 64-bit element array toa a byte element arrey to feed the
     * reference model.
     *
     * @param v64 Pointer to the 64-bit element array.
     * @param v8 Pointer to the 8-bit array where the result will be stored.
     * @param vl The vector length for the reduction.
     * @param sew The sew for the reduction.
     */
    static void v64_to_v8(const uint64_t *v64, uint8_t *v8, uint32_t vl, int sew);

    /**
     * @brief Sets up all the necessary parameters needed for the new reduction
     * to be executed.
     *
     * @param vsew The standard element width for this reduction.
     * @param vl The vector lenght for this reduction.
     * @param scalar The scalar value used in this reduction.
     * @param vs A byte-size element array containing the elements of the source
     * vector register
     * @param mask A byte-size element array containing the elements of the mask
     * register.
     * @param ins The instruction code of the reduction being executed.
     * @param frm The rounding mode for the floating point operations.
     * @param verb_lvl The verbosity level at wich the log should be generated.
     * @param act_verb_lvl The verbosity level at wich the environment is at
     * this moment.
     */
    void reduction_setup(uint8_t vsew, uint32_t vl, uint64_t scalar,
                         const uint8_t *vs, const uint8_t *mask,
                         const uint32_t ins, const uint32_t frm, int verb_lvl,
                         int act_verb_lvl, char tree_merge_enable, const uint64_t pc);

    /**
     * @brief Starts the execution of the reduction operation with the set
     * parameters and returns the result of this operation.
     *
     * @return uint64_t
     * */
    uint64_t do_reduction();

    /**
     * @brief Get the fflags object.
     *
     * @return uint_fast8_t
     */
    uint_fast8_t get_fflags() { return fflags; }

    /**
     * @brief Set the lane_num object.
     *
     * @param lane_num The number of lanes to be set.
     */
    void set_lane_num(uint8_t lane_num) { this->lane_num = lane_num; }

    /**
     * @brief Sets the number of accumulators for floating point and integer
     * operations.
     *
     * @param accum_num_fp The number of accumulators for floating point.
     * @param accum_num_int The number of accumulators for integer.
     */
    void set_accum_num(uint8_t accum_num_fp, uint8_t accum_num_int) {
        this->accum_num_fp = accum_num_fp;
        this->accum_num_int = accum_num_int;
    }

    /**
     * @brief Sets up the path for the log to be written.
     *
     * @param path The path to the file in which the log will be written.
     */
    void set_up_log(string path);

    // Returns sew of the result of the operation, in decimal (for widenings, it will be 2*SEW)
   int get_dec_result_sew();
   
   private:
    /**
     * @brief Executes the main loop of operations for ordered reductions and
     * returns the result of said operation.
     *
     * @return uint64_t
     */
    uint64_t reduction_ord();

    /**
     * @brief Executes the main loop of operations for unordered reductions and
     * returns the result of said operation.
     *
     * @return uint64_t
     */
    uint64_t reduction_unord();

    /**
     * @brief Performs the main operation for the reduction. This function
     * decides which operation must be performed by selecting it from the
     * instruction data, executes it and then returns the result.
     *
     * @param elem1 The first element of the operation.
     * @param elem2 The second element of the operation
     * @return uint64_t
     */
    uint64_t reduction_operation(uint64_t elem1, uint64_t elem2, bool accum1,
                                 bool accum2);

    /**
     * @brief Generates the element from the byte-size element array.
     *
     * @param start The index in which the element starts.
     * @param v The array from which the element must be gotten.
     * @return uint64_t
     */
    uint64_t get_elem(int start, const vector<uint8_t> &v);
    uint8_t get_mask_bit(int start, const vector<uint8_t> &v);

    /**
     * @brief Initializes the accumulators of every lane to 0 and sets the init
     * parameter to false.
     *
     * @param lanes The array of lanes.
     */
    void init_lanes(vector<lane> &lanes);

    /**
     * @brief Truncates the element given to the standard element size given.
     *
     * @param elem The element to be croped.
     * @return uint64_t
     */
    uint64_t adjust_to_sew(uint64_t elem);

    /**
     * @brief Performs a sign extension to the given size.
     *
     * @param a The element to perform the sign extension.
     * @param size The size to extrend the sign.
     * @return uint64_t
     */
    uint64_t sign_extend(uint64_t a, int size);

    /**
     * @brief Performs the merging of the accumulators inside a lane.
     * 
     * @param lane The lane that contains all the accumulators to be merged.
     * @param sew The sew of the actual operation.
     */
    void intralane_merge(lane *lane);

    /**
     * @brief Main method that performs the merging of the accumulators of a lane
     * in a tree based manner using recursion.
     * 
     * @param index_begin The first index of the lanes that the method gets
     * @param index_end  The las index of the lanes that the method gets
     * @param lane Pointer to the lane which accumulators are going to be merged
     * @return accum* The accumulator where the final result is stored
     */
    accum* intralane_branch_op(int index_begin, int index_end, lane *lane);

    /**
     * @brief Operates the accumulators with the actual reduction operation
     * 
     * @param accum1 The first accumulator for the operation
     * @param accum2 The second operator for the operation in which the result will be stored
     */
    void operate_accums(accum* accum1, accum* accum2);

    /**
     * @brief This function performs the merging of the accumulators from every
     * lane.
     *
     * @param lanes The array of lanes.
     */
    void merge_accums(vector<lane> &lanes);

    /**
     * @brief Performs the merging of the lanes in a linear way.
     *
     * @param lane_a The vector that contains all the lanes.
     */
    void interlane_merge(vector<lane> &lane_a);

    /**
     * @brief Performs the merging of the lanes in a tree-based strategy.
     * 
     * @param lane_a The vector that contains all the lanes
     */
    void tree_interlane_merge(vector<lane> &lane_a);

    /**
     * @brief Performs the merging of the lanes in a tree based strategy by
     * using recursion
     * 
     * @param index_begin The starting index for the interation
     * @param index_end The ending index for the iteration
     * @param lane_a The vector containing the lanes
     * @return lane* 
     */
    lane* tree_merge(int index_begin, int index_end, vector<lane> &lane_a);

    /**
     * @brief This function performs the folding for a given accumulator and
     * returns the result of this folding.
     *
     * @param a The accumulator.
     * @param size Size, in bites, of half of the elements left to fold in an
     * accumulator left.
     */
    void fold(accum &a, int size);

    /**
     * @brief Initializes the accumulator part with the value given, widening if
     * necessary.
     *
     * @param a The accumulator part to be initialized.
     * @param val The value to be used to initialize the accumulator part.
     */
    void init_accum_part(accum_part &a, uint64_t val);
};

#endif
