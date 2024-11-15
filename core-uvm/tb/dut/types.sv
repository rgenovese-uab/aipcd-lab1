typedef struct{
    logic           ready;
    logic [23:0]    addr;
    logic           valid;
} brom_req_t;


typedef struct{
    logic           valid;
    logic [31:0]    bits_data;
} brom_resp_t;
