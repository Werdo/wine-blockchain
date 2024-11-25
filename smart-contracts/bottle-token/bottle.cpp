#include "bottle.hpp"
#include <eosio/crypto.hpp>

void bottle::check_auth(name account) {
    require_auth(account);
}

void bottle::validate_attributes(const wine_attributes& attributes) {
    check(!attributes.winery.empty(), "Winery name cannot be empty");
    check(!attributes.vintage.empty(), "Vintage cannot be empty");
    check(!attributes.variety.empty(), "Variety cannot be empty");
    check(!attributes.region.empty(), "Region cannot be empty");
    check(!attributes.bottle_number.empty(), "Bottle number cannot be empty");
    check(attributes.production_date > 0, "Invalid production date");
    check(!attributes.batch_id.empty(), "Batch ID cannot be empty");
}

checksum256 bottle::generate_bottle_hash(const wine_attributes& attributes) {
    // Concatenate all attributes to create a unique string
    string concat_str = attributes.winery + 
                       attributes.vintage + 
                       attributes.variety + 
                       attributes.region + 
                       attributes.bottle_number + 
                       to_string(attributes.production_date) + 
                       attributes.batch_id;
    
    // Generate SHA256 hash
    return sha256(concat_str.c_str(), concat_str.size());
}

ACTION bottle::create(name owner, const wine_attributes& attributes) {
    // Verify authorization
    check_auth(owner);
    
    // Validate attributes
    validate_attributes(attributes);
    
    // Get bottles table
    bottles_table bottles(get_self(), get_self().value);
    
    // Generate unique bottle hash
    checksum256 bottle_hash = generate_bottle_hash(attributes);
    
    // Create new bottle token
    bottles.emplace(owner, [&](auto& row) {
        row.bottle_id = bottles.available_primary_key();
        row.owner = owner;
        row.attributes = attributes;
        row.attributes.bottle_hash = bottle_hash;
        row.current_status = "created";
        row.created_at = current_time_point().sec_since_epoch();
        row.updated_at = current_time_point().sec_since_epoch();
    });
    
    // Add creation event to history
    history_table history(get_self(), get_self().value);
    history.emplace(owner, [&](auto& row) {
        row.history_id = history.available_primary_key();
        row.bottle_id = bottles.available_primary_key() - 1;
        row.actor = owner;
        row.event_type = "creation";
        row.details = "Bottle token created";
        row.timestamp = current_time_point().sec_since_epoch();
    });
}

ACTION bottle::transfer(name from, name to, uint64_t bottle_id, string memo) {
    // Verify authorization
    check_auth(from);
    
    // Validate parameters
    check(is_account(to), "Recipient account does not exist");
    check(from != to, "Cannot transfer to self");
    
    // Get bottles table
    bottles_table bottles(get_self(), get_self().value);
    auto bottle_itr = bottles.find(bottle_id);
    check(bottle_itr != bottles.end(), "Bottle token does not exist");
    check(bottle_itr->owner == from, "Not authorized to transfer this bottle");
    
    // Update bottle ownership
    bottles.modify(bottle_itr, from, [&](auto& row) {
        row.owner = to;
        row.updated_at = current_time_point().sec_since_epoch();
    });
    
    // Record transfer in history
    history_table history(get_self(), get_self().value);
    history.emplace(from, [&](auto& row) {
        row.history_id = history.available_primary_key();
        row.bottle_id = bottle_id;
        row.actor = from;
        row.event_type = "transfer";
        row.details = "Transferred from " + from.to_string() + " to " + to.to_string() + ": " + memo;
        row.timestamp = current_time_point().sec_since_epoch();
    });
}

ACTION bottle::addhistory(uint64_t bottle_id, string event_type, string details) {
    // Get bottles table to verify bottle exists
    bottles_table bottles(get_self(), get_self().value);
    auto bottle_itr = bottles.find(bottle_id);
    check(bottle_itr != bottles.end(), "Bottle token does not exist");
    
    // Only owner or contract account can add history
    name actor = get_first_receiver();
    check(has_auth(bottle_itr->owner) || has_auth(get_self()), "Not authorized to add history");
    
    // Add event to history
    history_table history(get_self(), get_self().value);
    history.emplace(actor, [&](auto& row) {
        row.history_id = history.available_primary_key();
        row.bottle_id = bottle_id;
        row.actor = actor;
        row.event_type = event_type;
        row.details = details;
        row.timestamp = current_time_point().sec_since_epoch();
    });
    
    // Update bottle last modified timestamp
    bottles.modify(bottle_itr, same_payer, [&](auto& row) {
        row.updated_at = current_time_point().sec_since_epoch();
    });
}

ACTION bottle::updatestatus(uint64_t bottle_id, string new_status) {
    // Get bottles table
    bottles_table bottles(get_self(), get_self().value);
    auto bottle_itr = bottles.find(bottle_id);
    check(bottle_itr != bottles.end(), "Bottle token does not exist");
    
    // Only owner or contract account can update status
    name actor = get_first_receiver();
    check(has_auth(bottle_itr->owner) || has_auth(get_self()), "Not authorized to update status");
    
    // Update bottle status
    bottles.modify(bottle_itr, same_payer, [&](auto& row) {
        row.current_status = new_status;
        row.updated_at = current_time_point().sec_since_epoch();
    });
    
    // Add status update to history
    history_table history(get_self(), get_self().value);
    history.emplace(actor, [&](auto& row) {
        row.history_id = history.available_primary_key();
        row.bottle_id = bottle_id;
        row.actor = actor;
        row.event_type = "status_update";
        row.details = "Status updated to: " + new_status;
        row.timestamp = current_time_point().sec_since_epoch();
    });
}

ACTION bottle::burn(name owner, uint64_t bottle_id, string reason) {
    // Verify authorization
    check_auth(owner);
    
    // Get bottles table
    bottles_table bottles(get_self(), get_self().value);
    auto bottle_itr = bottles.find(bottle_id);
    check(bottle_itr != bottles.end(), "Bottle token does not exist");
    check(bottle_itr->owner == owner, "Not authorized to burn this bottle");
    
    // Add burn event to history before removing the bottle
    history_table history(get_self(), get_self().value);
    history.emplace(owner, [&](auto& row) {
        row.history_id = history.available_primary_key();
        row.bottle_id = bottle_id;
        row.actor = owner;
        row.event_type = "burn";
        row.details = "Bottle burned. Reason: " + reason;
        row.timestamp = current_time_point().sec_since_epoch();
    });
    
    // Remove the bottle token
    bottles.erase(bottle_itr);
}
