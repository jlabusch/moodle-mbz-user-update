Use case: Moodle course migrations where the target system has a newer version of the data for one or more users.

Workflow to modify `backup.mbz` so that user ID `123` is translated to `456`:

`./migrate.sh backup.mbz start              # prepares working directories`
`./migrate.sh backup.mbz find 123           # find instances of UID 123`
`./migrate.sh backup.mbz set 123 to 456     # migrate UID 123 to 456`
`./migrate.sh backup.mbz status             # show changes made thus far`
`./migrate.sh backup.mbz finish             # bundle the changes into a new .mbz`

