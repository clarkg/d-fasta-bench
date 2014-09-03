// The Computer Language Benchmarks Game
// http://benchmarkgame.alioth.debian.org
// 
// Fasta benchmark
// http://benchmarksgame.alioth.debian.org/u32/performance.php?test=fasta
//
// Heavily derived from C++ g++ #3 and thus
//
// converted to C++ from D by Rafal Rusin
// modified by Vaclav Haisman
// modified by The Anh to compile with g++ 4.3.2
// modified by Branamir Maksimovic
// modified by Kim Walisch
// modified by Tavis Bohne
// converted back to D from C++ by Clark Gredoña

enum int MAX_LINE_WIDTH = 60;

import std.algorithm;
import std.conv;
import std.range;
import std.stdint;
import std.stdio;

char[288] alu =
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGA"
    "TCACCTGAGGTCAGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACT"
    "AAAAATACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAG"
    "GCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGCGGAGGTTGCAGTGAGCCGAGATCGCG"
    "CCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";

alias IUB = Tuple!(float, "probability", char, "c");

// we use this separate array of probabilities in order to sum by using reduce
float[15] iubProbabilities = [0.27f, 0.12f, 0.12f, 0.27f, 0.02f, 0.02f, 0.02f,
                              0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f, 0.02f,
                              0.02f];
// the probabilities here will be replaced by the cumulative probabilities
auto iub = [IUB(0.00f, 'a'), IUB(0.00f, 'c'), IUB(0.00f, 'g'), IUB(0.00f, 't'),
            IUB(0.00f, 'B'), IUB(0.00f, 'D'), IUB(0.00f, 'H'), IUB(0.00f, 'K'),
            IUB(0.00f, 'M'), IUB(0.00f, 'N'), IUB(0.00f, 'R'), IUB(0.00f, 'S'),
            IUB(0.00f, 'V'), IUB(0.00f, 'W'), IUB(0.00f, 'Y')];

float[4] homosapienProbs = [0.3029549426680f,
                            0.1979883004921f,
                            0.1975473066391f,
                            0.3015094502008f];
auto homosapiens = [IUB(0.00f, 'a'), IUB(0.00f, 'c'),
                    IUB(0.00f, 'g'), IUB(0.00f, 't')];

float genRandom(in float max = 1.0f)
{
    static immutable int IM   = 139968, IA = 3877, IC = 29573;
    static int           last = 42;
    last = (last * IA + IC) % IM;
    return max * last * (1.0f / IM);
}

template CharRangeTemplate(Range)
{
    class RepeatFunctorType {
    public this(Range range, int length) {
        this.range = cycle(range);
    }

    public char opCall()
    {
        // would use moveFront but it doesn't actually remove the element
        // like it's supposed to
        auto result = to!char (range.front);
        range = range.drop(1);
        return result;
    }

    private Cycle!(Range) range;
    }
}

template TupleRangeTemplate(Range)
{
    class RandomFunctorType {
    public this(Range range) {
        this.range = range;
    }

    public char opCall()
    {
        immutable float p     = genRandom(1.0f);
        auto            tuple = (find !"a.probability >= b" (range, p)).front;
        return tuple.c;
    }

    private Range range;
    }
}

template FunctorTemplate(F) {
	/// Prints in FASTA format, building char by char according to F.
    public void make(int charsRemaining, F functor)
    {
        char line[MAX_LINE_WIDTH];
        while (charsRemaining > 0)
        {
            auto currLineWidth = charsRemaining;
            if (currLineWidth > MAX_LINE_WIDTH)
            {
                currLineWidth = MAX_LINE_WIDTH;
            }

            for (auto i = 0; i < currLineWidth; ++i)
            {
                line[i] = functor();
            }
            writeln(line[0..currLineWidth]);
            charsRemaining -= currLineWidth;
        }
    }
}

void main(string[] args)
{
    auto n = 1000;
    if (args.length < 2 || (n = to!int (args[1])) < 0)
    {
        writeln("Usage: ", args[0], " LENGTH");
        return;
    }

    // convert expected probability of selecting each nucleotide into
    // cumulative probabilities
    auto arrLength = iubProbabilities.length;     // cache length on stack
    for (auto i = 0; i < arrLength; i++)
    {
        iub[i][0] = reduce!((a, b) => a + b)(iubProbabilities[0..i + 1]);
    }
    arrLength = homosapienProbs.length;
    float[4] cumulativeHomosapienProbs;
    for (auto i = 0; i < arrLength; i++)
    {
        homosapiens[i][0] = reduce!((a, b) => a + b)(homosapienProbs[0..i + 1]);
    }

    writeln(">ONE Homo sapiens alu");
    alias charRangeTemplateInst = CharRangeTemplate!(char[]);
    auto  repeatFunctor         = new charRangeTemplateInst.RepeatFunctorType(alu, n * 2);

    alias funTemplateInst = FunctorTemplate!(charRangeTemplateInst.RepeatFunctorType);
    funTemplateInst.make(n * 2, repeatFunctor);

    writeln(">TWO IUB ambiguity codes");
    alias iubRangeTemplateInst = TupleRangeTemplate!(typeof(iub));
    alias randFunTemplateInst  = FunctorTemplate!(iubRangeTemplateInst.RandomFunctorType);

    auto  randomFunctor = new iubRangeTemplateInst.RandomFunctorType(iub);
    randFunTemplateInst.make(n * 3, randomFunctor);

    writeln(">THREE Homo sapiens frequency");
    randomFunctor = new iubRangeTemplateInst.RandomFunctorType(homosapiens);
    randFunTemplateInst.make(n * 5, randomFunctor);
}
