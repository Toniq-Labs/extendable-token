import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";

module Util
{
    public module ArrayUtil
    {
        public func push<A>(currentArray : [A], element : A) : [A]
        {
            let iter = Iter.fromArray(currentArray);
            let arrLen = Iter.size(iter);
            var newArr = Array.init<A>(arrLen + 1, element);
            for (i in currentArray.keys())
            {
                newArr[i] := currentArray[i];
            };
            return Array.freeze(newArr);
        };

    }


}