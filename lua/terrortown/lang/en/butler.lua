local L = LANG.GetLanguageTableReference("en")

L[BUTLER.name] = "Butler"
L["info_popup_" .. BUTLER.name] = [[You are a Butler!
Try to protect your Player..]]
L["body_found_" .. BUTLER.abbr] = "They were Butler."
L["search_role_" .. BUTLER.abbr] = "This person was a Butler!"
L["target_" .. BUTLER.name] = "Butler"
L["ttt2_desc_" .. BUTLER.name] = [[The Butler needs to win with their Players team]]

L["tooltip_butler_fail_score"] = "Butler Failed: {score}"
L["butler_fail_score"] = "Butler Failed:"
L["title_event_butler_fail"] = "A Butler failed to protect their Target"
L["desc_event_butler_fail"] = "{butler} has failed to protect {target}."

// Convars
// L["label_bodygrd_damage_guarded_death"] = "Damage on target death"