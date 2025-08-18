export interface Chain {
    name: string;
    rpc: string;
}

export interface Chains {
    testnets: Record<number, Chain>;
    mainnets: Record<number, Chain>;
}

export interface Config {
    delayMs: number;
    value: string;
    gasPrice: string;
    to?: string;
}

export interface TransactionDetails {
    from: string;
    to: string;
    value: bigint;
    gasPrice: bigint;
    data: string;
}