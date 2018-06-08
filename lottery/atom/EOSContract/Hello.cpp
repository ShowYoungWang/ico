#include <eosiolib/eosio.hpp>
#include <eosiolib/print.hpp>


using namespace eosio;

class Hello : public eosio::contract {
    public:
        using contract::contract;
        void hi(eosio::name user) {
            print("Hello", user);
        }
};
EOSIO_ABI(Hello, (hi));
