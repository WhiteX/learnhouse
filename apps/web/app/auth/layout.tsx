'use client';

import { OrgProvider } from '@components/Contexts/OrgContext'
import ErrorUI from '@components/Objects/StyledElements/Error/Error'
import { useSearchParams } from 'next/navigation'
import React from 'react'

export default function AuthLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const searchParams = useSearchParams()
    // Use optional chaining and nullish coalescing for type safety
    const orgslug = searchParams?.get('orgslug') ?? null
    if (orgslug) {
        return <OrgProvider orgslug={orgslug}>{children}</OrgProvider>
    } else {
        return <ErrorUI message='Organization not specified' submessage='Please access this page from an Organization' />
    }
}