#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>
#include <eosio/system.hpp>
#include <string>

using namespace std;
using namespace eosio;

CONTRACT bottle : public contract {
    public:
        using contract::contract;

        // Constructor
        bottle(name receiver, name code, datastream<const char*> ds)
            : contract(receiver, code, ds) {}

        // Token structure
        struct wine_attributes {
            string winery;            // Bodega productora
            string vintage;           // Año de cosecha
            string variety;           // Variedad de uva
            string region;            // Región/DO
            string bottle_number;     // Número único de botella
            uint64_t production_date; // Fecha de producción
            string batch_id;          // ID del lote
            checksum256 bottle_hash;  // Hash único de la botella
        };

        // Actions
        ACTION create(
            name owner,
            const wine_attributes& attributes
        );

        ACTION transfer(
            name from,
            name to,
            uint64_t bottle_id,
            string memo
        );

        ACTION addhistory(
            uint64_t bottle_id,
            string event_type,
            string details
        );

        ACTION updatestatus(
            uint64_t bottle_id,
            string new_status
        );

        ACTION burn(
            name owner,
            uint64_t bottle_id,
            string reason
        );

    private:
        // Bottles table
        TABLE bottle_info {
            uint64_t bottle_id;
            name owner;
            wine_attributes attributes;
            string current_status;
            uint64_t created_at;
            uint64_t updated_at;

            uint64_t primary_key() const { return bottle_id; }
            uint64_t by_owner() const { return owner.value; }
            checksum256 by_hash() const { return attributes.bottle_hash; }
        };

        // History table
        TABLE history_info {
            uint64_t history_id;
            uint64_t bottle_id;
            name actor;
            string event_type;
            string details;
            uint64_t timestamp;

            uint64_t primary_key() const { return history_id; }
            uint64_t by_bottle() const { return bottle_id; }
        };

        typedef multi_index<"bottles"_n, bottle_info,
            indexed_by<"byowner"_n, const_mem_fun<bottle_info, uint64_t, &bottle_info::by_owner>>,
            indexed_by<"byhash"_n, const_mem_fun<bottle_info, checksum256, &bottle_info::by_hash>>
        > bottles_table;

        typedef multi_index<"history"_n, history_info,
            indexed_by<"bybottle"_n, const_mem_fun<history_info, uint64_t, &history_info::by_bottle>>
        > history_table;

        // Internal functions
        void check_auth(name account);
        void validate_attributes(const wine_attributes& attributes);
        checksum256 generate_bottle_hash(const wine_attributes& attributes);
};
