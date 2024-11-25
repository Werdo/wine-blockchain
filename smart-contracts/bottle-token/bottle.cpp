#include "bottle.hpp"
#include <eosio/crypto.hpp>

void bottle::check_auth(name account) {
    require_auth(account);
}
