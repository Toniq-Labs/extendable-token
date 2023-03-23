/// Things we can compare in tests
///
/// This module contains the `Testable<A>` abstraction, which bundles
/// `toText` and `equals` for a type `A` so we can use them as "expected"
/// values in tests.
/// It also contains a few helpers to build `Testable`'s for compound types
/// like Arrays and Optionals. If you want to test your own objects or control
/// how things are printed and compared in your own tests you'll need to create
/// your own `Testable`'s.
/// ```motoko
/// import T "mo:matchers/Testable";
///
/// type Person = { name : Text, surname : ?Text };
/// // Helper
/// let optText : Testable<(?Text)> = T.optionalTestable(T.textTestable)
/// let testablePerson : Testable<Person> = {
///    display = func (person : Person) : Text =
///        person.name # " " #
///        optText.display(person.surname)
///    equals = func (person1 : Person, person2 : Person) : Bool =
///        person1.name == person2.name and
///        optText.equals(person1.surname, person2.surname)
/// }
/// ```
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Int "mo:base/Int";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Prim "mo:prim";

module {
    /// Packs up all the functions we need to compare and display values under test
    public type Testable<A> = {
        display : A -> Text;
        equals : (A, A) -> Bool
    };

    /// A value combined with its `Testable`
    public type TestableItem<A> = {
        display : A -> Text;
        equals : (A, A) -> Bool;
        item : A;
    };

    public let textTestable : Testable<Text> = {
        // TODO Actually escape the text here
        display = func (text : Text) : Text { "\"" # text # "\"" };
        equals = func (t1 : Text, t2 : Text) : Bool { t1 == t2 }
    };

    public func text(t : Text) : TestableItem<Text> = {
        item = t;
        display = textTestable.display;
        equals = textTestable.equals;
    };

    public let natTestable : Testable<Nat> = {
        display = func (nat : Nat) : Text = Nat.toText(nat);
        equals = func (n1 : Nat, n2 : Nat) : Bool = n1 == n2
    };

    public func nat(n : Nat) : TestableItem<Nat> = {
        item = n;
        display = natTestable.display;
        equals = natTestable.equals;
    };

    public let nat8Testable : Testable<Nat8> = {
        display = func (nat : Nat8) : Text {Nat8.toText(nat)};
        equals = func (n1 : Nat8, n2 : Nat8) : Bool {n1 == n2};
    };

    public func nat8(n : Nat8) : TestableItem<Nat8> = {
        item = n;
        display = nat8Testable.display;
        equals = nat8Testable.equals;
    };

    public let nat16Testable : Testable<Nat16> = {
        display = func (nat : Nat16) : Text {Nat16.toText(nat)};
        equals = func (n1 : Nat16, n2 : Nat16) : Bool {n1 == n2};
    };

    public func nat16(n : Nat16) : TestableItem<Nat16> = {
        item = n;
        display = nat16Testable.display;
        equals = nat16Testable.equals;
    };

    public let nat32Testable : Testable<Nat32> = {
        display = func (nat : Nat32) : Text {Nat32.toText(nat)};
        equals = func (n1 : Nat32, n2 : Nat32) : Bool {n1 == n2};
    };

    public func nat32(n : Nat32) : TestableItem<Nat32> = {
        item = n;
        display = nat32Testable.display;
        equals = nat32Testable.equals;
    };


    public let nat64Testable : Testable<Nat64> = {
        display = func (nat : Nat64) : Text {Nat64.toText(nat)};
        equals = func (n1 : Nat64, n2 : Nat64) : Bool {n1 == n2};
    };

    public func nat64(n : Nat64) : TestableItem<Nat64> = {
        item = n;
        display = nat64Testable.display;
        equals = nat64Testable.equals;
    };

    public let intTestable : Testable<Int> = {
        display = func (n : Int) : Text = Int.toText(n);
        equals = func (n1 : Int, n2 : Int) : Bool = n1 == n2
    };

    public func int(n : Int) : TestableItem<Int> = {
        item = n;
        display = intTestable.display;
        equals = intTestable.equals;
    };

    public let boolTestable : Testable<Bool> = {
        display = func (n : Bool) : Text = Bool.toText(n);
        equals = func (n1 : Bool, n2 : Bool) : Bool = n1 == n2
    };

    public func bool(n : Bool) : TestableItem<Bool> = {
        item = n;
        display = boolTestable.display;
        equals = boolTestable.equals;
    };

    public let charTestable : Testable<Char> = {
        display = func (n : Char) : Text { "'" # Prim.charToText(n) # "'" };
        equals = func (n1 : Char, n2 : Char) : Bool { n1 == n2 };
    };

    public func char(n : Char) : TestableItem<Char> {
        {
            item = n;
            display = charTestable.display;
            equals = charTestable.equals;
        }
    };

    public func arrayTestable<A>(testableA : Testable<A>) : Testable<[A]> {
        {
            display = func (xs : [A]) : Text =
                "[" # joinWith(Array.map<A, Text>(xs, testableA.display), ", ") # "]";
            equals = func (xs1 : [A], xs2 : [A]) : Bool =
                Array.equal(xs1, xs2, testableA.equals)
        }
    };

    public func array<A>(testableA : Testable<A>, xs : [A]) : TestableItem<[A]> {
        let testableAs = arrayTestable(testableA);
        {
            item = xs;
            display = testableAs.display;
            equals = testableAs.equals;
        };
    };

    public func listTestable<A>(testableA : Testable<A>) : Testable<List.List<A>> = {
        display = func (xs : List.List<A>) : Text =
          // TODO fix leading comma
            "[" #
            List.foldLeft(xs, "", func(acc : Text, x : A) : Text =
                acc # ", " # testableA.display(x)
            ) #
            "]";
        equals = func (xs1 : List.List<A>, xs2 : List.List<A>) : Bool =
            List.equal(xs1, xs2, testableA.equals)
    };

    public func list<A>(testableA : Testable<A>, xs : List.List<A>) : TestableItem<List.List<A>> {
        let testableAs = listTestable(testableA);
        {
            item = xs;
            display = testableAs.display;
            equals = testableAs.equals;
        };
    };

    public func optionalTestable<A>(testableA : Testable<A>) : Testable<?A> {
        {
            display = func (x : ?A) : Text = switch(x) {
                case null { "null" };
                case (?a) { "(?" # testableA.display(a) # ")" };
            };
            equals = func (x1 : ?A, x2 : ?A) : Bool = switch(x1) {
                case null switch(x2) {
                    case null { true };
                    case _ { false };
                };
                case (?x1) switch(x2) {
                    case null { false };
                    case (?x2) { testableA.equals(x1, x2) };
                };
            };
        }
    };

    public func optional<A>(testableA : Testable<A>, x : ?A) : TestableItem<?A> {
        let testableOA = optionalTestable(testableA);
        {
            item = x;
            display = testableOA.display;
            equals = testableOA.equals;
        };
    };

    public func resultTestable<R, E>(
        rTestable : Testable<R>,
        eTestable : Testable<E>
    ) : Testable<Result.Result<R, E>> = {
        display = func (r : Result.Result<R, E>) : Text = switch r {
            case (#ok(ok)) {
                "#ok(" # rTestable.display(ok) # ")"
            };
            case (#err(err)) {
                "#err(" # eTestable.display(err) # ")"
            };
        };
        equals = func (r1 : Result.Result<R, E>, r2 : Result.Result<R, E>) : Bool = switch (r1, r2) {
            case (#ok(ok1), #ok(ok2)) {
                rTestable.equals(ok1, ok2)
            };
            case (#err(err1), #err(err2)) {
                eTestable.equals(err1, err2)
            };
            case (_) { false };
        };
    };

    public func result<R, E>(
      rTestable : Testable<R>,
      eTestable : Testable<E>,
      x : Result.Result<R, E>
    ) : TestableItem<Result.Result<R, E>> {
        let resTestable = resultTestable(rTestable, eTestable);
        {
            display = resTestable.display;
            equals = resTestable.equals;
            item = x;
        }
    };

    public func tuple2Testable<A, B>(ta : Testable<A>, tb : Testable<B>) : Testable<(A, B)> {
      {
          display = func ((a, b) : (A, B)) : Text =
              "(" # ta.display(a) # ", " # tb.display(b) # ")";
          equals = func((a1, b1) : (A, B), (a2, b2) : (A, B)) : Bool =
              ta.equals(a1, a2) and tb.equals(b1, b2);
      }
    };

    public func tuple2<A, B>(ta : Testable<A>, tb : Testable<B>, x : (A, B)) : TestableItem<(A, B)> {
      let testableTAB = tuple2Testable(ta, tb);
      {
          item = x;
          display = testableTAB.display;
          equals = testableTAB.equals;
      }
    };

    func joinWith(xs : [Text], sep : Text) : Text {
        let size = xs.size();

        if (size == 0) return "";
        if (size == 1) return xs[0];

        var result = xs[0];
        var i = 0;
        label l loop {
            i += 1;
            if (i >= size) { break l; };
            result #= sep # xs[i]
        };
        result
    };
}
