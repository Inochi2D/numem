# Numem Contribution Guidelines

Thank you for considering to contribute to numem!

Numem, unlike other packages under the Inochi2D umbrella is far more strict in what should
and should not be added to the codebase. This is to ensure API stability for consumers
of the numem API.

## General Rules

1. Do not add any external dependencies.
2. Only include essential features for memory managment.
3. New features should have associated unittests under the tests directory.
4. Be sure to mark functions with attributes appropriately.
    * Fundamentally unsafe code should not be marked trusted!
5. Follow the code style of the rest of the project.

# Creating Issues

## Reporting bugs
Reported bugs should have clear steps for reproduction, bonus if you provide a minimal dustmite example.

## Requesting features
Most features that may be requested will likely be rejected; you may want to submit them to nucore instead.
numem is meant to be minimal in size to decrease the surface of how much may break.

# Creating pull-requests

If you'd like to make a feature pull-request please bring up a suggestion via Issues first,
Bugfixes will only be merged if all of the tests pass. If a pull-request is a work-in-progress,
please mark it as a Draft.
