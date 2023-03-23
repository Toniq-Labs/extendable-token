import HM "mo:base/HashMap";
import Text "mo:base/Text";
import Matchers "../src/Matchers";
import HMMatchers "../src/matchers/Hashmap";
import T "../src/Testable";
import Suite "../src/Suite";

let equals10 = Matchers.equals(T.nat(10));
let equals20 = Matchers.equals(T.nat(20));
let greaterThan10: Matchers.Matcher<Nat> = Matchers.greaterThan(10);
let greaterThan20: Matchers.Matcher<Nat> = Matchers.greaterThan(20);
let map : HM.HashMap<Text, Nat> = HM.HashMap<Text, Nat>(5, Text.equal, Text.hash);
map.put("key1", 20);
map.put("key2", 10);

let suite = Suite.suite("Testing the testing", [
    Suite.suite("equality", [
        Suite.test("nats1", 10, equals10),
        Suite.test("nats2", 20, equals10),
        Suite.test("Chars", 'a', Matchers.equals(T.char('b'))),
    ]),
    Suite.testLazy("Lazy test execution", func(): Nat = 20, equals10),
    Suite.test("Described as", 20, Matchers.describedAs("20's a lot mate.", equals10)),
    Suite.suite("Combining matchers", [
        Suite.test("anything", 10, Matchers.anything<Nat>()),

        Suite.test("anyOf1", 20, Matchers.anyOf([equals10, equals20])),
        Suite.test("anyOf2", 15, Matchers.anyOf([equals10, equals20])),

        Suite.test("allOf1", 30, Matchers.allOf([greaterThan10, greaterThan20])),
        Suite.test("allOf2", 15, Matchers.allOf([greaterThan10, greaterThan20])),
        Suite.test("allOf2", 8, Matchers.allOf([greaterThan10, greaterThan20])),
    ]),

    Suite.suite("Comparing numbers", [
        Suite.test("greaterThan1", 20, greaterThan10),
        Suite.test("greaterThan2", 5, greaterThan10),
    ]),
    Suite.suite("Array matchers", [
        Suite.test("Should match", [10, 20], Matchers.array([equals10, equals20])),
        Suite.test("Should fail", [20, 10], Matchers.array([equals10, equals20])),
        Suite.test("Length mismatch", ([] : [Nat]), Matchers.array([equals10, equals20])),
    ]),

    Suite.suite("Hashmap matchers", [
        Suite.test("Should have key", map, HMMatchers.hasKey<Text, Nat>(T.text("key1"))),
        Suite.test("Should fail with missing key", map, HMMatchers.hasKey<Text, Nat>(T.text("unknown"))),
        Suite.test("Should match at key", map, HMMatchers.atKey(T.text("key1"), equals20)),
        Suite.test("should fail at key", map, HMMatchers.atKey(T.text("key2"), equals20)),
        Suite.test("Should fail with missing key2", map, HMMatchers.atKey(T.text("unknown"), equals20)),
    ])    
]);

Suite.run(suite)
