/// Matchers for Hashmaps
///
/// This module contains utility matchers that make it easier
/// to write assertions that involve Hashmaps.

import HM "mo:base/HashMap";
import M "../Matchers";
import Option "mo:base/Option";
import T "../Testable";

module {

    /// Tests that a HashMap contains a key
    public func hasKey<K, V>(key : T.TestableItem<K>) : M.Matcher<HM.HashMap<K, V>> = {
        matches = func (map : HM.HashMap<K, V>) : Bool = Option.isSome(map.get(key.item));
        describeMismatch = func (map : HM.HashMap<K, V>, description : M.Description) {
            description.appendText("Missing key " # key.display(key.item))
        };
    };

    /// Tests that a HashMap matches at a given key
    public func atKey<K, V>(key : T.TestableItem<K>, matcher : M.Matcher<V>) : M.Matcher<HM.HashMap<K, V>> = {
        matches = func (map : HM.HashMap<K, V>) : Bool =
            Option.getMapped(map.get(key.item), matcher.matches, false);
        describeMismatch = func (map : HM.HashMap<K, V>, description : M.Description) {
            switch (map.get(key.item)) {
                case null {
                    description.appendText("Missing key " # key.display(key.item))
                };
                case (?v) {
                    matcher.describeMismatch(v, description)
                };
            }
        };
    };
}
