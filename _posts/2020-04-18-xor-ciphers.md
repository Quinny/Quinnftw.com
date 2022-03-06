---
title: XOR Ciphers
author: Quinn
layout: post
permalink: /xor-ciphers/
category: misc
---

# Background

## Ciphers

A "cipher", in the context of this blog post. is a collection of operations that
can be applied to some information which disguises its original contents. The
original contents can (hopefully) only be recovered by an individual who knows
the key to the cipher.

## XOR

XOR (an acronym for *exclusive or*) is a function of two bits that produces 1
bit. The function applied is essentially additional modulo 2, i.e.
<code>x + y % 2</code>.

This produces the following output table:

| X | Y | X XOR Y |
|---|---|---------|
| 0 | 0 | 0       |
| 0 | 1 | 1       |
| 1 | 0 | 1       |
| 1 | 1 | 0       |

A useful mnemonic for remembering the above table is "One or the other, but not both".

The two most interesting properties of the XOR function for ciphers are:

1. <code>x XOR x = 0</code>
2. <code>x XOR 0 = x</code>

The reason why these properties are important will become clear soon.

# Repeating Key XOR Cipher

Suppose we have some text: <code>The secret is 42</code>, as well as a key: <code>dog</code>. We can encipher the text using the key by applying the XOR
function between the characters in the key and the text, i.e.

<div align='center'>
<code>ciphertext = key ^ text</code>
</div><br />

To compensate for the text being longer than the key, we can *repeat* the key
multiple times so that things line up nicely.

<div align='center'>
<code>
The secret is 42<br>
dogdogdogdogdogd
</code>
</div><br />

This repeating technique is the reason why this is called a *repeating key*
cipher.

## Encrypting with a Repeating Key

The code for applying this cipher to some text file is pretty simple:

```python
def repeating_key(key, plaintext):
    key_index = 0
    for c in plaintext:
        yield key[key_index] ^ c
        key_index = (key_index + 1) % len(key)

plaintext = open("secret.txt").read()
repeating_key(key="dog", plaintext)
```

Deciphering the text can be done by re-running the enciphered text through the
`repeating_key` function.

```python
cipher_text = repeating_key(key="dog", plaintext)
plaintext_prime = repeating_key(key="dog", str(cipher_text))
```

This works because of the two properties listed previously:

```
cipher_text = plaintext ^ key
plaintext_prime = ciphertext ^ key
                = plaintext ^ key ^ key
                = plaintext ^ 0 (propery I)
                = plaintext     (property II)
```

## Breaking the Cipher

Unfortunately repeating key XOR ciphers are fairly easy to break using something
called <i>[frequency analysis](https://privacycanada.net/attack-vectors/frequency-analysis/)</i>.

Suppose we assume that the space character (' ') is the most commonly occurring
character in the plaintext. This is a somewhat reasonable assumption that should
hold for most bodies of text (that or 'e', which typically also occurs fairly
often).

Since our encryption process simply repeated the encryption key over the text,
the most common character in the ciphertext is very likely to be `key ^ ' '`. If
we then take the most 3 commonly occurring characters of the cipher text and XOR
them with ' ', the key should be revealed.

```python
def break_repeating_key(cipher_text,
                        suspected_key_length,
                        suspected_most_common_character):
  for (character, _) in Counter(ciphertext).most_common(suspected_key_length):
    yeild chr(c ^ ord(suspected_most_common_character))
```

This should result in something like:

```
g
d
o
```

Which you'll notice is our key, but slightly out of order. Finding the correct order
takes a little more work, but is fairly trivial. If we make one more assumption,
the language of the plaintext, we can try different orderings of the key until
the resulting text contains some threshold of valid words.

```python
def find_correct_ordering(ciphertext,
                          suspected_key_elements,
                          valid_words,
                          valid_word_threshold):
  for key_permutation in itertools.permuations(suspected_key_elements):
    words = repeating_key(key_permutation, ciphertext).split(' ')
    valid_word_count = count(lambda word: word in valid_words, words)
    if valid_word_count > valid_word_threshold:
      return suspected_key_elements
  return None
```

# Linear Feedback XOR

XOR ciphering can be bolstered against frequency analysis by iteratively
generating new key text based on the input plaintext. This technique is
formally called a [Linear Feedback Shift Register](https://en.wikipedia.org/wiki/Linear-feedback_shift_register).
Constantly generating new key text prevents from producing similar letter
frequencies in the resulting cipher text.

## Encrypting with Feedback

The code for a feedback XOR cipher is slightly more complicated than the repeating
key variant, but still relatively straight forward.

```python
def linear_feedback(key, plaintext):
    sliding_window = key
    for c in plaintext:
        mixer = sum(sliding_window) % 255
        cipher_char = c ^ mixer
        yield cipher_char
        sliding_window = sliding_window[1:]
        sliding_window.append(cipher_char)
```

The `sliding_window` variable here acts as our shift register, constantly
changing based on the input text.

Decrypting is almost the same as encrypting, but not quite:

```python
def linear_feedback_decrypt(key, ciphertext):
    sliding_window = key
    for c in ciphertext:
        mixer = sum(sliding_window) % 255
        plaintext_char = c ^ mixer
        yield plaintext_char
        sliding_window = sliding_window[1:]
        sliding_window.append(c)
```

The sliding window is populated with the raw ciphertext instead of the output
of the XOR operation.

## Breaking the Cipher

Simple frequency analysis no longer works, since our `mixer` prevents from
key repetition. This type of cipher is vulnerable to a [known plaintext attack](https://en.wikipedia.org/wiki/Known-plaintext_attack), however [that
approach](https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Uses_in_cryptography) is too complicated for this blog post.
